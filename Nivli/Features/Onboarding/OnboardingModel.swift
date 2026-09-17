import Foundation

/// The answers collected while someone walks through onboarding, before they are written to
/// the shared state.
///
/// A value type on purpose: the flow holds one, each page edits a field through a binding,
/// and the flow copies the whole thing into `NivliState` at every Continue. Nothing here is
/// derived — `OnboardingModel` does the deriving — so a test can build a draft by hand.
struct OnboardingDraft: Equatable {
    /// Why they are here (page 2). Multi-select, order is the order they were tapped.
    var goals: [Goal] = []
    /// How often they move today (page 3).
    var frequency: Frequency? = nil
    /// Roughly how much of the day goes to the phone (page 4).
    var phoneHours: PhoneHours? = nil
    /// How long a workout has to be to unlock the apps (page 6).
    var minimumMinutes: Int = SharedConstants.defaultMinimumMinutes
    /// Whether the evening nudge was turned on (page 7). Set from the state after asking,
    /// because the person can still refuse the system prompt.
    var reminderEnabled: Bool = false
    /// Minutes after local midnight for that nudge; 18 * 60 is 6:00 pm.
    var reminderMinutes: Int = 18 * 60
    /// Whether Apple Health access was granted (page 6).
    var healthConnected: Bool = false

    init() {}
}

/// The gating rules for the onboarding flow, kept away from SwiftUI so they can be tested.
///
/// Page indices are zero-based and match the order of the pages in `OnboardingFlow`:
/// 0 welcome · 1 goals · 2 frequency · 3 phone hours · 4 apps · 5 health · 6 reminders ·
/// 7 summary. Step 8 is the paywall, which is not an onboarding page and has no Continue.
enum OnboardingModel {
    /// How many pages there are before the paywall.
    static let pageCount = 8

    /// Whether the primary button on `step` is enabled.
    ///
    /// - Parameters:
    ///   - step: the zero-based page index.
    ///   - draft: the answers so far.
    ///   - selectionOK: whether the apps page is satisfied — something was picked, or Screen
    ///     Time is denied or unavailable and there is nothing to pick. The flow works this
    ///     out from `AppModel`, because it depends on live authorization rather than the draft.
    /// - Returns: `true` when the person can move on.
    static func canContinue(step: Int, draft: OnboardingDraft, selectionOK: Bool) -> Bool {
        switch step {
        case 1: return !draft.goals.isEmpty
        case 2: return draft.frequency != nil
        case 3: return draft.phoneHours != nil
        case 4: return selectionOK
        default: return true
        }
    }

    /// The words on the primary button for `step`.
    static func primaryTitle(step: Int) -> String {
        switch step {
        case 0: return "Get started"
        case 6: return "Turn on reminders"
        default: return "Continue"
        }
    }

    /// The words on the quiet button under the primary one, or `nil` when there is none.
    /// Only the reminders page offers a way past without saying yes.
    static func secondaryTitle(step: Int) -> String? {
        step == 6 ? "Not now" : nil
    }

    /// The minute-of-day a `Date` falls on, in the given calendar. Used to turn the
    /// reminder time picker back into the integer the shared state stores.
    static func minutesFromMidnight(for date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Today at `minutes` past midnight, for a `DatePicker` to sit on. Falls back to the
    /// reference date's own time if the calendar cannot build it, which it always can.
    static func date(fromMinutesFromMidnight minutes: Int, on reference: Date = Date(), calendar: Calendar = .current) -> Date {
        let clamped = max(0, min(minutes, 24 * 60 - 1))
        return calendar.date(
            bySettingHour: clamped / 60,
            minute: clamped % 60,
            second: 0,
            of: reference
        ) ?? reference
    }
}
