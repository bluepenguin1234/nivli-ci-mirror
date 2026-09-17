import Foundation
@testable import Nivli

/// A calendar that does not depend on the machine running the tests: Gregorian, New York,
/// Sunday-first. Every test that touches days uses this one so results are identical on a
/// laptop and on a cloud Mac.
let testCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    if let zone = TimeZone(identifier: "America/New_York") {
        calendar.timeZone = zone
    }
    return calendar
}()

/// A `DayKey` written the way it reads.
func day(_ year: Int, _ month: Int, _ day: Int) -> DayKey {
    DayKey(year: year, month: month, day: day)
}

/// A workout on a day, at a fixed time of day so ordering inside a day is predictable.
func makeWorkout(
    on day: DayKey,
    minutes: Int,
    kind: WorkoutKind = .run,
    source: WorkoutEntry.Source = .manual,
    id: UUID = UUID(),
    hour: Int = 9
) -> WorkoutEntry {
    let start = day.date(in: testCalendar).addingTimeInterval(TimeInterval(hour * 3600))
    return WorkoutEntry(id: id, day: day, start: start, minutes: minutes, kind: kind, source: source)
}

/// A `NivliState` with only the parts a test cares about set.
///
/// `hasSelection` is driven by `hasSelection:` rather than by real tokens, because a test
/// process cannot mint an `ApplicationToken` — only the system can.
func makeState(
    onboardingComplete: Bool = true,
    hasSelection: Bool = true,
    minimumMinutes: Int = SharedConstants.defaultMinimumMinutes,
    weeklyRestDays: Set<Int> = [],
    oneOffRestDays: Set<DayKey> = [],
    workouts: [WorkoutEntry] = [],
    entitlementValidUntil: Date? = Date.distantFuture,
    healthEnabled: Bool = false,
    reminderEnabled: Bool = false,
    goals: [Goal] = [],
    currentFrequency: Frequency? = nil,
    dailyPhoneHours: PhoneHours? = nil
) -> NivliState {
    NivliState().with { state in
        state.onboardingComplete = onboardingComplete
        state.selectionOverrideForTesting = hasSelection
        state.minimumMinutes = minimumMinutes
        state.weeklyRestDays = weeklyRestDays
        state.oneOffRestDays = oneOffRestDays
        state.workouts = workouts.sorted { $0.start < $1.start }
        state.entitlementValidUntil = entitlementValidUntil
        state.healthEnabled = healthEnabled
        state.reminderEnabled = reminderEnabled
        state.goals = goals
        state.currentFrequency = currentFrequency
        state.dailyPhoneHours = dailyPhoneHours
    }
}

/// A date at noon on a day, for tests that need a `now`.
func noon(on day: DayKey) -> Date {
    day.date(in: testCalendar).addingTimeInterval(12 * 3600)
}

/// A unique `UserDefaults` suite name so two tests never see each other's data.
func throwawaySuiteName(_ label: String = "store") -> String {
    "com.bluepenguin.nivli.tests.\(label).\(UUID().uuidString)"
}
