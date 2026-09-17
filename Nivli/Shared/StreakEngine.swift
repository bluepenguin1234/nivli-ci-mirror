import Foundation

/// The pure rules behind every number Nivli shows. No Apple framework beyond Foundation,
/// no state of its own: every function takes a `NivliState` and gives an answer.
enum StreakEngine {
    /// How far back `longestStreak(_:calendar:)` and the rest-day bridge will walk between
    /// two workouts before giving up. A year of consecutive rest days is already absurd, and
    /// the cap keeps a corrupt state from spinning forever.
    private static let maximumBridgeDays = 400

    /// Whether a day is a rest day — either a weekday the person always rests on, or a
    /// one-off "take today off".
    static func isRestDay(_ state: NivliState, day: DayKey, calendar: Calendar = .current) -> Bool {
        if state.oneOffRestDays.contains(day) { return true }
        return state.weeklyRestDays.contains(day.weekday(in: calendar))
    }

    /// Every workout logged on a day, in the order they are stored (oldest first).
    static func workouts(_ state: NivliState, on day: DayKey) -> [WorkoutEntry] {
        state.workouts.filter { $0.day == day }
    }

    /// The first workout that day long enough to unlock the apps, if there is one.
    static func qualifyingWorkout(_ state: NivliState, day: DayKey) -> WorkoutEntry? {
        state.workouts.first { $0.day == day && $0.minutes >= state.minimumMinutes }
    }

    /// The current streak: consecutive qualifying days ending today, with rest days bridging
    /// the gaps and counting for nothing.
    ///
    /// Today is special. If today is already done it counts; if it is not, the streak is not
    /// broken yet — the day is simply not over — so the walk continues to yesterday. From
    /// yesterday backwards a day that is neither qualifying nor a rest day ends the streak.
    static func streak(_ state: NivliState, today: DayKey, calendar: Calendar = .current) -> Int {
        guard let earliest = state.workouts.map(\.day).min() else { return 0 }

        var count = 0
        var cursor = today
        if qualifyingWorkout(state, day: today) != nil {
            count = 1
        }
        cursor = cursor.previous(in: calendar)

        while cursor >= earliest {
            if qualifyingWorkout(state, day: cursor) != nil {
                count += 1
            } else if !isRestDay(state, day: cursor, calendar: calendar) {
                break
            }
            cursor = cursor.previous(in: calendar)
        }
        return count
    }

    /// The best streak in the whole history, using the same rest-day bridging.
    ///
    /// Walks the unique qualifying days oldest first: two of them belong to the same streak
    /// when every day between them is a rest day (a day-apart pair has nothing between it,
    /// so it always bridges).
    static func longestStreak(_ state: NivliState, calendar: Calendar = .current) -> Int {
        let days = qualifyingDays(state)
        var best = 0
        var current = 0
        var previous: DayKey?

        for day in days {
            if let previous, bridges(state, from: previous, to: day, calendar: calendar) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    /// How one dot on the week strip reads.
    enum DayStatus: String, Equatable, CaseIterable {
        /// A qualifying workout was logged.
        case done
        /// A rest day: nothing was locked and nothing was expected.
        case rest
        /// The day passed without a qualifying workout and without being a rest day.
        case missed
        /// Today, not done yet. The day is still open, so it is neither done nor missed.
        case today
        /// A day that has not arrived. Never produced by `weekStrip`; it exists for previews
        /// and for any strip that shows days ahead of today.
        case future
    }

    /// The seven dots on Home: the last seven days ending today, oldest first.
    ///
    /// Today is `.done` when a qualifying workout exists and `.today` otherwise — an open
    /// day is never shown as missed, and never as rest, so the dot keeps reading as "your
    /// move". Earlier days are `.done`, then `.rest`, then `.missed`.
    static func weekStrip(_ state: NivliState, today: DayKey, calendar: Calendar = .current) -> [DayStatus] {
        var days: [DayKey] = [today]
        var cursor = today
        for _ in 0..<6 {
            cursor = cursor.previous(in: calendar)
            days.append(cursor)
        }

        return days.reversed().map { day -> DayStatus in
            let isDone = qualifyingWorkout(state, day: day) != nil
            if day == today {
                return isDone ? .done : .today
            }
            if isDone { return .done }
            if isRestDay(state, day: day, calendar: calendar) { return .rest }
            return .missed
        }
    }

    /// The milestone a streak just hit, if it landed exactly on one.
    static func milestoneReached(streak: Int) -> Int? {
        SharedConstants.streakMilestones.first { $0 == streak }
    }

    /// A state with one more workout in it: same id replaces rather than duplicates, and the
    /// list stays sorted oldest first.
    static func addingWorkout(_ state: NivliState, _ entry: WorkoutEntry) -> NivliState {
        state.with { copy in
            copy.workouts.removeAll { $0.id == entry.id }
            copy.workouts.append(entry)
            copy.workouts.sort { $0.start < $1.start }
        }
    }

    /// Merges Apple Health workouts in, ignoring any whose `HKWorkout` UUID is already
    /// stored, and reports which ones were actually new.
    static func mergingHealthWorkouts(
        _ state: NivliState,
        _ entries: [WorkoutEntry]
    ) -> (state: NivliState, added: [WorkoutEntry]) {
        var knownIDs = Set(state.workouts.map(\.id))
        var added: [WorkoutEntry] = []
        for entry in entries where !knownIDs.contains(entry.id) {
            knownIDs.insert(entry.id)
            added.append(entry)
        }
        guard !added.isEmpty else { return (state, []) }

        let merged = state.with { copy in
            copy.workouts.append(contentsOf: added)
            copy.workouts.sort { $0.start < $1.start }
        }
        return (merged, added)
    }

    /// The unique days with a qualifying workout, oldest first.
    private static func qualifyingDays(_ state: NivliState) -> [DayKey] {
        let days = state.workouts
            .filter { $0.minutes >= state.minimumMinutes }
            .map(\.day)
        return Array(Set(days)).sorted()
    }

    /// Whether every day strictly between two days is a rest day.
    private static func bridges(
        _ state: NivliState,
        from earlier: DayKey,
        to later: DayKey,
        calendar: Calendar
    ) -> Bool {
        var cursor = earlier.next(in: calendar)
        var steps = 0
        while cursor < later {
            if steps >= maximumBridgeDays { return false }
            if !isRestDay(state, day: cursor, calendar: calendar) { return false }
            cursor = cursor.next(in: calendar)
            steps += 1
        }
        return cursor == later
    }
}
