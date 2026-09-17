import Foundation
import FamilyControls
import Observation
import os

/// Something that went wrong, said in the person's language. Shown inline; never a crash.
struct UserFacingError: Error, Equatable {
    let title: String
    let message: String
}

/// What happened when a workout was logged, for the celebration and the Home refresh.
struct LogResult: Equatable {
    let entry: WorkoutEntry
    /// The apps are open now (and were not before this log, or were already open).
    let unlocked: Bool
    /// The entry is shorter than the person's minimum, so it is kept but unlocks nothing.
    let underMinimum: Bool
    let streak: Int
    /// A milestone hit by this log (3, 7, 14, …), for the confetti. `nil` otherwise.
    let milestone: Int?
}

/// The one object every screen talks to. Owns the in-memory mirror of the shared state,
/// the services, and the derived numbers (decision, streak, week strip), and is the only
/// place that writes to `SharedStore` from the app.
///
/// Rule of thumb: views read properties and call one method; they never touch a service
/// or the store directly.
@MainActor
@Observable
final class AppModel {
    let sharedStore: SharedStore
    let subscriptions: SubscriptionStore
    let health: HealthKitService
    let screenTime: ScreenTimeAuthorization
    let notifications: NotificationService
    private let shields: ShieldController
    private let calendar: Calendar
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "app")

    /// The last state loaded from or written to the shared store.
    private(set) var state: NivliState
    private(set) var decision: ShieldDecision = .open(.notOnboarded)
    private(set) var streak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var weekStrip: [StreakEngine.DayStatus] = []
    /// The workout that unlocked today, if any.
    private(set) var todayWorkout: WorkoutEntry?
    /// Set when the daily re-lock schedule could not be started (the app still applies
    /// shields on every foreground, so this is a warning, not a failure).
    private(set) var monitoringError: UserFacingError?

    init(
        sharedStore: SharedStore = .shared,
        subscriptions: SubscriptionStore,
        health: HealthKitService,
        screenTime: ScreenTimeAuthorization,
        notifications: NotificationService,
        shields: ShieldController = ShieldController(),
        calendar: Calendar = .current
    ) {
        self.sharedStore = sharedStore
        self.subscriptions = subscriptions
        self.health = health
        self.screenTime = screenTime
        self.notifications = notifications
        self.shields = shields
        self.calendar = calendar
        self.state = sharedStore.load()
        recompute()
    }

    /// The model the real app runs with.
    static func live() -> AppModel {
        AppModel(
            subscriptions: SubscriptionStore(),
            health: HealthKitService(),
            screenTime: ScreenTimeAuthorization(),
            notifications: NotificationService()
        )
    }

    // MARK: - Lifecycle

    /// Called synchronously from the app's initialiser, before any view exists. Health
    /// background delivery only reaches an app that re-registers its observer query at
    /// process launch, and iOS may launch Nivli in the background for exactly that reason,
    /// so the observer cannot wait for the first screen's `.task`.
    func prepareForLaunch() {
        guard state.healthEnabled else { return }
        health.startObserving { [weak self] in
            await self?.healthDidChange()
        }
    }

    /// Called once from the app's `.task`: starts StoreKit, Health observing, and does the
    /// first refresh. Safe to call again.
    func start() async {
        subscriptions.onEntitlementChange = { [weak self] validUntil in
            Task { @MainActor in self?.recordEntitlement(validUntil: validUntil) }
        }
        await subscriptions.start()
        screenTime.refresh()
        prepareForLaunch()
        await refresh()
    }

    /// Reload the shared state, pull today's Health workouts, recompute, and set the shields
    /// to match. Called on every foreground and after anything changes elsewhere.
    func refresh() async {
        state = sharedStore.load()
        await importHealthWorkouts()
        recompute()
        applyShields()
    }

    // MARK: - Writes

    /// Change the shared state and keep everything derived in step.
    func update(_ change: (inout NivliState) -> Void) {
        state = sharedStore.update(change)
        recompute()
        applyShields()
    }

    /// Log a workout by hand. Under the minimum it is kept but unlocks nothing.
    @discardableResult
    func logWorkout(kind: WorkoutKind, minutes: Int, at start: Date = Date()) -> LogResult {
        let wasLocked = decision.isLocked
        let entry = WorkoutEntry(start: start, minutes: minutes, kind: kind, source: .manual, calendar: calendar)
        let next = StreakEngine.addingWorkout(state, entry)
        sharedStore.save(next)
        state = next
        recompute()
        applyShields()
        let unlocked = wasLocked && !decision.isLocked
        let milestone = unlocked ? StreakEngine.milestoneReached(streak: streak) : nil
        logger.log("Manual workout logged (\(minutes) min); unlocked=\(unlocked)")
        return LogResult(
            entry: entry,
            unlocked: unlocked,
            underMinimum: minutes < state.minimumMinutes,
            streak: streak,
            milestone: milestone
        )
    }

    /// The paywall succeeded (or a purchase was restored) at the end of onboarding.
    func completeOnboarding() {
        update { $0.onboardingComplete = true }
        startDailyMonitoring()
    }

    /// A new choice of apps from the picker (onboarding or Settings).
    func applySelection(_ selection: FamilyActivitySelection) {
        update { $0.selection = selection }
        if state.onboardingComplete { startDailyMonitoring() }
    }

    /// A one-off rest day. The streak survives; nothing is locked until tomorrow.
    func takeTodayOff() {
        let today = DayKey.today(calendar: calendar)
        update { $0.oneOffRestDays.insert(today) }
    }

    /// Ask for Health access; on success import today's workouts and start observing.
    @discardableResult
    func connectHealth() async -> Bool {
        let granted = await health.requestAccess()
        update { $0.healthEnabled = granted }
        if granted {
            health.startObserving { [weak self] in
                await self?.healthDidChange()
            }
            await refresh()
        }
        return granted
    }

    /// Turn the evening nudge on or off, asking for permission when turning it on.
    @discardableResult
    func setReminder(enabled: Bool, minutesFromMidnight: Int) async -> Bool {
        var allowed = true
        if enabled {
            allowed = await notifications.requestPermission()
        }
        let effective = enabled && allowed
        update {
            $0.reminderEnabled = effective
            $0.reminderMinutesFromMidnight = minutesFromMidnight
        }
        if !effective {
            notifications.cancelEveningNudge()
        }
        return allowed
    }

    /// Removes every shield and forgets everything Nivli stored (Settings → Reset).
    func resetEverything() {
        shields.clear()
        ActivitySchedule.stopMonitoring()
        notifications.cancelEveningNudge()
        sharedStore.reset()
        state = sharedStore.load()
        recompute()
    }

    /// StoreKit told us the entitlement changed. `nil` means not subscribed.
    func recordEntitlement(validUntil: Date?) {
        guard state.entitlementValidUntil != validUntil else { return }
        update { $0.entitlementValidUntil = validUntil }
    }

    // MARK: - Derived

    var isSubscribed: Bool {
        guard let until = state.entitlementValidUntil else { return false }
        return until > Date()
    }

    var today: DayKey { DayKey.today(calendar: calendar) }

    var isRestDayToday: Bool {
        StreakEngine.isRestDay(state, day: today, calendar: calendar)
    }

    // MARK: - Private

    private func recompute() {
        let today = self.today
        decision = ShieldPolicy.decision(state, now: Date(), calendar: calendar)
        streak = StreakEngine.streak(state, today: today, calendar: calendar)
        longestStreak = max(StreakEngine.longestStreak(state, calendar: calendar), streak)
        weekStrip = StreakEngine.weekStrip(state, today: today, calendar: calendar)
        todayWorkout = StreakEngine.qualifyingWorkout(state, day: today)
    }

    private func applyShields() {
        shields.refresh(sharedStore: sharedStore, now: Date())
        rescheduleNudge()
    }

    /// Keeps the evening nudge honest: once today is unlocked (or is a rest day) the next
    /// nudge is tomorrow's, not tonight's.
    private func rescheduleNudge() {
        guard state.onboardingComplete, state.reminderEnabled else { return }
        notifications.scheduleEveningNudge(
            minutesFromMidnight: state.reminderMinutesFromMidnight,
            skipToday: !decision.isLocked,
            calendar: calendar
        )
    }

    private func importHealthWorkouts() async {
        guard state.healthEnabled, health.isAvailable else { return }
        let entries = await health.workoutsToday(calendar: calendar)
        guard !entries.isEmpty else { return }
        let merged = StreakEngine.mergingHealthWorkouts(state, entries)
        guard !merged.added.isEmpty else { return }
        sharedStore.save(merged.state)
        state = merged.state
        logger.log("Imported \(merged.added.count) Health workout(s)")
    }

    /// Health delivered a new sample (possibly while the app is in the background).
    private func healthDidChange() async {
        let wasLocked = decision.isLocked
        await refresh()
        if wasLocked && !decision.isLocked {
            notifications.postUnlocked(streak: streak)
        }
    }

    private func startDailyMonitoring() {
        guard state.hasSelection else { return }
        do {
            try ActivitySchedule.startDailyMonitoring()
            monitoringError = nil
        } catch {
            logger.error("Daily monitoring could not start: \(error.localizedDescription, privacy: .public)")
            monitoringError = UserFacingError(
                title: "Midnight re-lock unavailable",
                message: "Nivli will lock your apps each time you open it, but iOS did not accept the daily schedule. This is expected in the simulator."
            )
        }
    }
}
