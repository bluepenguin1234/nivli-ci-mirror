import Foundation

/// Everything Apple Health, kept away from the rest of `AppModel`.
///
/// Health is the one input Nivli does not control: iOS never says whether the read was
/// allowed, samples arrive while the app is closed, and background delivery outlives any
/// switch the person flips. So this side of the model owns the observer's whole life —
/// registering it at launch, and genuinely tearing it down when Apple Health is turned off.
@MainActor
extension AppModel {
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

    /// The Settings switch. Turning it off is a real off: the observer stops and background
    /// delivery is handed back to iOS, so Nivli stops being woken for workouts even though
    /// the read permission itself can only be withdrawn in the Health app.
    func setHealthEnabled(_ enabled: Bool) async {
        if enabled {
            await connectHealth()
        } else {
            health.stopObserving()
            update { $0.healthEnabled = false }
        }
    }

    /// Today's Health workouts that Nivli has not recorded yet, merged into the current
    /// state — or `nil` when there is nothing new. `refresh()` does the writing, so the
    /// shared store still has exactly one caller.
    func mergedHealthWorkouts() async -> NivliState? {
        guard state.healthEnabled, health.isAvailable else { return nil }
        let entries = await health.workoutsToday(calendar: calendar)
        guard !entries.isEmpty else { return nil }
        let merged = StreakEngine.mergingHealthWorkouts(state, entries)
        guard !merged.added.isEmpty else { return nil }
        logger.log("Imported \(merged.added.count, privacy: .private) Health workout(s)")
        return merged.state
    }

    /// Health delivered a new sample (possibly while the app is in the background).
    func healthDidChange() async {
        let wasLocked = decision.isLocked
        await refresh()
        if wasLocked && !decision.isLocked {
            notifications.postUnlocked(streak: streak)
        }
    }
}
