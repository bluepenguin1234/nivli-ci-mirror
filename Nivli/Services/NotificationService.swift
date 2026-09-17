import Foundation
import UserNotifications
import os

/// The two notifications Nivli ever sends: "your apps are open again" when Health finds a
/// workout while the app is closed, and an optional evening nudge.
///
/// Both are local. Nothing is scheduled unless the person turned it on, and every failure is
/// swallowed — a notification that does not arrive is never worth an error on screen.
final class NotificationService: @unchecked Sendable {
    /// How many days ahead the evening nudge is armed for.
    private static let nudgeDayCount = 7
    /// "nivli.nudge.0" is today, "nivli.nudge.6" is six days out.
    private static let nudgeIdentifierPrefix = "nivli.nudge."
    /// The single repeating request earlier versions scheduled. Removed on sight so an
    /// upgrade never ends up with two evening nudges.
    private static let legacyNudgeIdentifier = "nivli.nudge"
    /// The one-off "apps unlocked" message.
    private static let unlockedIdentifier = "nivli.unlocked"

    private static var nudgeIdentifiers: [String] {
        (0..<nudgeDayCount).map { "\(nudgeIdentifierPrefix)\($0)" }
    }

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "notifications")

    init() {}

    /// Shows the system prompt, once per install. `false` when it was refused or failed.
    func requestPermission() async -> Bool {
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        return granted ?? false
    }

    /// Whether notifications can actually be delivered right now — the person may have
    /// turned them off in iOS Settings long after saying yes here.
    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    /// Arms the evening nudge for the week ahead: seven separate one-shot notifications, one
    /// per day at the chosen time, rather than a single repeating one.
    ///
    /// A local notification cannot ask whether today is already done, so the only way to keep
    /// the promise ("only on days you have not moved yet") is to re-decide the schedule
    /// often. `AppModel.refresh()` calls this on every foreground, every Health delivery and
    /// every change, and each call replaces all seven requests: today's is dropped when
    /// `skipToday` is true (the day is already unlocked, or a rest day) or when the time has
    /// already passed, and the six days after it are armed unconditionally, because nobody
    /// can know yet how those days will go.
    ///
    /// A week of headroom is what makes this safe. Even if Nivli is not opened again, the
    /// nudge keeps arriving for seven days, and any refresh in that window pushes the window
    /// out again — where a single repeating request would have kept nudging someone who had
    /// already worked out.
    func scheduleEveningNudge(minutesFromMidnight: Int, skipToday: Bool = false, calendar: Calendar = .current) {
        cancelEveningNudge()
        let clamped = max(0, min(minutesFromMidnight, 24 * 60 - 1))
        let hour = clamped / 60
        let minute = clamped % 60
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        for day in 0..<Self.nudgeDayCount {
            guard let midnight = calendar.date(byAdding: .day, value: day, to: startOfToday) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: midnight)
            components.hour = hour
            components.minute = minute
            if day == 0, skipToday || (calendar.date(from: components) ?? now) <= now { continue }

            let request = UNNotificationRequest(
                identifier: "\(Self.nudgeIdentifierPrefix)\(day)",
                content: nudgeContent(),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            add(request)
        }
    }

    /// Removes every evening nudge, pending or delivered, including the single repeating one
    /// older versions of Nivli used.
    func cancelEveningNudge() {
        let identifiers = Self.nudgeIdentifiers + [Self.legacyNudgeIdentifier]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func nudgeContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Still locked"
        content.body = "Your apps are waiting. Move, log it, and they open."
        content.sound = .default
        return content
    }

    /// Health found a qualifying workout while Nivli was closed: the apps are open again.
    func postUnlocked(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Apps unlocked"
        content.body = streak > 1 ? "Workout detected. Streak: \(streak) days." : "Workout detected."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.unlockedIdentifier,
            content: content,
            trigger: nil
        )
        add(request)
    }

    /// One place to hand a request to iOS, so a failure is logged exactly once and never
    /// reaches a caller.
    private func add(_ request: UNNotificationRequest) {
        center.add(request) { [logger] error in
            if let error {
                logger.error("A notification could not be scheduled: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
