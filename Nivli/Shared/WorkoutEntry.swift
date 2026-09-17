import Foundation

/// The nine kinds of movement Nivli can record. Honour system: the kind only changes the
/// icon and the wording, never whether a workout counts.
enum WorkoutKind: String, Codable, CaseIterable, Identifiable {
    case run
    case walk
    case strength
    case cycle
    case swim
    case yoga
    case hiit
    case sport
    case other

    var id: String { rawValue }

    /// Title case, for the picker grid and any standalone label.
    var title: String {
        switch self {
        case .run: return "Run"
        case .walk: return "Walk"
        case .strength: return "Strength"
        case .cycle: return "Cycle"
        case .swim: return "Swim"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .sport: return "Sport"
        case .other: return "Other"
        }
    }

    /// The same word inside a sentence — "42 min run". Only HIIT keeps its capitals.
    var summaryNoun: String {
        self == .hiit ? "HIIT" : title.lowercased()
    }

    /// The SF Symbol shown in the kind grid and next to a logged workout.
    var symbolName: String {
        switch self {
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .strength: return "dumbbell.fill"
        case .cycle: return "figure.outdoor.cycle"
        case .swim: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .hiit: return "figure.highintensity.intervaltraining"
        case .sport: return "sportscourt.fill"
        case .other: return "figure.mixed.cardio"
        }
    }
}

/// One workout, however it got here.
///
/// A value type with no mutating methods: changing a workout means building a new one, and
/// `StreakEngine.addingWorkout(_:_:)` returns a new state rather than editing the old.
struct WorkoutEntry: Codable, Equatable, Identifiable, Hashable {
    /// Where a workout came from. Health entries are the ones that unlock the apps without
    /// the person opening Nivli.
    enum Source: String, Codable {
        case manual
        case health
    }

    /// For `.health` this is the `HKWorkout` UUID, which is what deduplicates repeated
    /// imports of the same workout. For `.manual` it is a fresh UUID.
    let id: UUID
    /// The local day the workout is counted against — derived from `start`.
    let day: DayKey
    /// When the workout began.
    let start: Date
    /// Duration in whole minutes, rounded by whoever created the entry.
    let minutes: Int
    let kind: WorkoutKind
    let source: Source

    init(id: UUID = UUID(), day: DayKey, start: Date, minutes: Int, kind: WorkoutKind, source: Source) {
        self.id = id
        self.day = day
        self.start = start
        self.minutes = minutes
        self.kind = kind
        self.source = source
    }

    /// Convenience for a manual log: the day is derived from `start` in the given calendar.
    init(
        id: UUID = UUID(),
        start: Date,
        minutes: Int,
        kind: WorkoutKind,
        source: Source,
        calendar: Calendar = .current
    ) {
        self.init(
            id: id,
            day: DayKey(start, calendar: calendar),
            start: start,
            minutes: minutes,
            kind: kind,
            source: source
        )
    }

    /// How the workout is attributed on Home — "logged by you" or "Apple Health".
    var sourceLabel: String {
        switch source {
        case .manual: return "logged by you"
        case .health: return "Apple Health"
        }
    }

    /// "42 min run" — the line under the status hero, before the source label.
    var summary: String {
        "\(minutes) min \(kind.summaryNoun)"
    }

    /// A copy with a different duration, keeping identity and everything else.
    func withMinutes(_ newMinutes: Int) -> WorkoutEntry {
        WorkoutEntry(id: id, day: day, start: start, minutes: newMinutes, kind: kind, source: source)
    }

    /// A copy with a different kind, keeping identity and everything else.
    func withKind(_ newKind: WorkoutKind) -> WorkoutEntry {
        WorkoutEntry(id: id, day: day, start: start, minutes: minutes, kind: newKind, source: source)
    }
}
