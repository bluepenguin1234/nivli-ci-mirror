import Foundation

/// One local calendar day, stored as the three numbers a person would read off a date.
///
/// Nivli's whole contract is "did you move *today*", so the day — not the instant — is the
/// unit everything is keyed on. Storing year/month/day rather than a `Date` means a day
/// never drifts when the device changes time zone, and two devices in different zones would
/// still agree about what "2026-09-16" means.
///
/// `Comparable` orders chronologically by (year, month, day).
struct DayKey: Codable, Hashable, Comparable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    /// The day with these exact components. No validation: callers build these from a
    /// `Calendar`, and an impossible day simply never matches a real one.
    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The local calendar day a moment in time falls on.
    init(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    /// The start of this day (local midnight).
    ///
    /// Returns `.distantPast` rather than crashing if the components cannot form a date —
    /// which only happens for a day that never existed in this calendar. Callers compare
    /// and order days; a sentinel that sorts before everything is harmless there.
    func date(in calendar: Calendar = .current) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return .distantPast }
        return calendar.startOfDay(for: date)
    }

    /// The day before this one.
    func previous(in calendar: Calendar = .current) -> DayKey {
        shifted(by: -1, in: calendar)
    }

    /// The day after this one.
    func next(in calendar: Calendar = .current) -> DayKey {
        shifted(by: 1, in: calendar)
    }

    /// The `Calendar` weekday number, 1 = Sunday through 7 = Saturday — the same numbers
    /// `NivliState.weeklyRestDays` holds.
    func weekday(in calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: date(in: calendar))
    }

    /// Today, in the given calendar.
    static func today(calendar: Calendar = .current, now: Date = Date()) -> DayKey {
        DayKey(now, calendar: calendar)
    }

    /// ISO-style `2026-09-16`, used in logs and as the value people see in exported data.
    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private func shifted(by days: Int, in calendar: Calendar) -> DayKey {
        let start = date(in: calendar)
        guard let moved = calendar.date(byAdding: .day, value: days, to: start) else { return self }
        return DayKey(moved, calendar: calendar)
    }
}
