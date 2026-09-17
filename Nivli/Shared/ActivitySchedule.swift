import Foundation
import DeviceActivity

/// The daily schedule that wakes the monitor extension at midnight so the shields go back on
/// without anyone opening Nivli.
enum ActivitySchedule {
    /// The one activity Nivli monitors.
    static let name = DeviceActivityName(SharedConstants.dailyActivityName)

    /// Starts (or restarts) the 00:00 → 23:59 repeating schedule.
    ///
    /// The existing schedule is stopped first, because `startMonitoring` throws if the same
    /// name is already being monitored. Throws are left to the caller: a failure here is
    /// degraded but not fatal — the app still refreshes the shields on every foreground.
    ///
    /// Never call this when Screen Time authorization was refused or is unavailable.
    static func startDailyMonitoring(center: DeviceActivityCenter = DeviceActivityCenter()) throws {
        center.stopMonitoring([name])
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        try center.startMonitoring(name, during: schedule)
    }

    /// Stops the daily schedule. Used when the subscription lapses or the person clears
    /// their selection, so the extension stops being woken for nothing.
    static func stopMonitoring(center: DeviceActivityCenter = DeviceActivityCenter()) {
        center.stopMonitoring([name])
    }
}
