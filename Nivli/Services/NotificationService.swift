import Foundation
import UserNotifications
import os

/// The two notifications Nivli ever sends: "your apps are open again" when Health finds a
/// workout while the app is closed, and an optional evening nudge.
///
/// Both are local. Nothing is scheduled unless the person turned it on, and every failure is
/// swallowed — a notification that does not arrive is never worth an error on screen.
final class NotificationService: @unchecked Sendable {
    /// The repeating evening nudge.
    private static let nudgeIdentifier = "nivli.nudge"
    /// The one-off "apps unlocked" message.
    private static let unlockedIdentifier = "nivli.unlocked"

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "notifications")

    init() {}

    /// Shows the system prompt, once per install. `false` when it was refused or failed.
    func requestPermission() async -> Bool {
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
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

    /// Schedules the evening nudge at a local time of day.
    ///
    /// A local notification cannot ask whether today is already done, so `AppModel` calls
    /// this again after every change: with `skipToday` false the nudge repeats daily from
    /// today; with `skipToday` true (the day is already unlocked, or a rest day) it is a
    /// single nudge tomorrow, and the next refresh turns it back into the daily one. Nivli
    /// refreshes on every foreground and on every Health delivery, so the nudge only reaches
    /// someone who has not moved yet, as the copy promises.
    func scheduleEveningNudge(minutesFromMidnight: Int, skipToday: Bool = false, calendar: Calendar = .current) {
        cancelEveningNudge()
        let clamped = max(0, min(minutesFromMidnight, 24 * 60 - 1))
        let content = UNMutableNotificationContent()
        content.title = "Still locked"
        content.body = "Your apps are waiting. Move, log it, and they open."
        content.sound = .default

        var components = DateComponents(hour: clamped / 60, minute: clamped % 60)
        var repeats = true
        if skipToday {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
            let day = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.year = day.year
            components.month = day.month
            components.day = day.day
            repeats = false
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let request = UNNotificationRequest(
            identifier: Self.nudgeIdentifier,
            content: content,
            trigger: trigger
        )
        add(request)
    }

    /// Removes the evening nudge, pending or delivered.
    func cancelEveningNudge() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.nudgeIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.nudgeIdentifier])
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
