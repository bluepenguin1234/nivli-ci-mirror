import Foundation

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
