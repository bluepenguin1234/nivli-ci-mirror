import DeviceActivity
import ManagedSettings
import os

/// Puts the shields back on at the start of every day, without anyone opening Nivli.
///
/// The app registers a repeating 00:00 → 23:59 schedule (`ActivitySchedule`), and iOS wakes
/// this extension at both ends of it. Both ends do the same thing: ask `ShieldController` to
/// re-read the shared state and apply or clear. All the thinking lives in `ShieldPolicy`, so
/// the extension and the app can never disagree.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "monitor")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("Interval did start: \(activity.rawValue, privacy: .public)")
        ShieldController().refresh()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("Interval did end: \(activity.rawValue, privacy: .public)")
        ShieldController().refresh()
    }
}
