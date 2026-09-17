import Foundation

/// Why the apps are open right now. Every reason is a reason *not* to shield, which is how
/// Nivli fails open: anything unusual leaves the phone alone.
enum OpenReason: Equatable {
    /// No valid subscription. Nivli never shields someone who is not paying.
    case notSubscribed
    /// Onboarding was not finished, so there is nothing to enforce yet.
    case notOnboarded
    /// Nothing was picked in the Family Activity picker.
    case nothingSelected
    /// A weekly rest day or a one-off "take today off".
    case restDay
    /// Today is done — this is the workout that unlocked it.
    case workedOut(WorkoutEntry)
}

/// The answer to "should anything be shielded right now".
enum ShieldDecision: Equatable {
    case open(OpenReason)
    case locked

    /// Convenience for the UI, which mostly cares about the ring and not the reason.
    var isLocked: Bool {
        self == .locked
    }
}

/// The single place that decides whether the shields go on.
///
/// The app calls this on every foreground and the monitor extension calls it at the start of
/// every day, so both always reach the same answer from the same stored state.
enum ShieldPolicy {
    /// Checks, in this exact order: subscription → onboarding → selection → rest day →
    /// today's workout. The order matters — someone who has not paid is never told they are
    /// locked, whatever else is true of their state.
    static func decision(
        _ state: NivliState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ShieldDecision {
        guard let validUntil = state.entitlementValidUntil, validUntil >= now else {
            return .open(.notSubscribed)
        }
        guard state.onboardingComplete else { return .open(.notOnboarded) }
        guard state.hasSelection else { return .open(.nothingSelected) }

        let today = DayKey(now, calendar: calendar)
        if StreakEngine.isRestDay(state, day: today, calendar: calendar) {
            return .open(.restDay)
        }
        if let workout = StreakEngine.qualifyingWorkout(state, day: today) {
            return .open(.workedOut(workout))
        }
        return .locked
    }
}
