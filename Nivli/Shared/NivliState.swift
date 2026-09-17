import Foundation
import FamilyControls

/// What brought someone to Nivli. Multi-select in onboarding; used only to choose copy.
enum Goal: String, Codable, CaseIterable, Identifiable {
    case habit
    case screenTime
    case stronger
    case feelBetter
    case sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .habit: return "Build a workout habit"
        case .screenTime: return "Cut my screen time"
        case .stronger: return "Get stronger"
        case .feelBetter: return "Feel better day to day"
        case .sleep: return "Sleep better"
        }
    }

    var symbolName: String {
        switch self {
        case .habit: return "flame.fill"
        case .screenTime: return "iphone.slash"
        case .stronger: return "dumbbell.fill"
        case .feelBetter: return "heart.fill"
        case .sleep: return "moon.stars.fill"
        }
    }
}

/// How often someone moves today, before Nivli.
enum Frequency: String, Codable, CaseIterable, Identifiable {
    case rarely
    case oneToTwo
    case threeToFour
    case daily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rarely: return "Rarely"
        case .oneToTwo: return "1–2 days a week"
        case .threeToFour: return "3–4 days a week"
        case .daily: return "Almost every day"
        }
    }
}

/// Roughly how much of a day goes to the phone.
enum PhoneHours: String, Codable, CaseIterable, Identifiable {
    case one
    case two
    case threePlus
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .one: return "About an hour"
        case .two: return "2 hours"
        case .threePlus: return "3 hours or more"
        case .unknown: return "I'd rather not know"
        }
    }

    /// The "that's about N days a year" line on onboarding page 4. `nil` when the person
    /// asked not to be told, and the page shows nothing.
    var daysPerYear: Int? {
        switch self {
        case .one: return 15
        case .two: return 30
        case .threePlus: return 46
        case .unknown: return nil
        }
    }
}

/// Everything Nivli knows, in one `Codable` value shared by the app and both extensions.
///
/// Decoding is deliberately total: every field is read with `decodeIfPresent` and falls back
/// to its default, so a payload written by an older or newer build — or a payload missing a
/// key entirely — still produces a usable state instead of throwing.
struct NivliState: Codable, Equatable {
    var onboardingComplete: Bool = false
    /// The apps, categories and sites that wait. Empty until the person picks something;
    /// Nivli never sees what is inside, only whether it is empty.
    var selection: FamilyActivitySelection = FamilyActivitySelection()
    var minimumMinutes: Int = SharedConstants.defaultMinimumMinutes
    /// `Calendar` weekday numbers, 1 = Sunday.
    var weeklyRestDays: Set<Int> = []
    var oneOffRestDays: Set<DayKey> = []
    /// Both sources, kept sorted by `start` (oldest first).
    var workouts: [WorkoutEntry] = []
    /// `nil` means never subscribed. A lifetime purchase maps to `.distantFuture`.
    var entitlementValidUntil: Date? = nil
    var healthEnabled: Bool = false
    var reminderEnabled: Bool = false
    /// Minutes after local midnight; 18 * 60 is 6:00 pm.
    var reminderMinutesFromMidnight: Int = 18 * 60
    var goals: [Goal] = []
    var currentFrequency: Frequency? = nil
    var dailyPhoneHours: PhoneHours? = nil

    /// Test-only escape hatch for `hasSelection`.
    ///
    /// A unit test cannot build a real `ApplicationToken` — the system mints them — so there
    /// is no way to populate `selection` off-device. When this is non-`nil`, `hasSelection`
    /// returns it instead of inspecting the tokens. It is not part of `CodingKeys`, so it is
    /// never written to or read from the App Group; production code leaves it `nil`.
    var selectionOverrideForTesting: Bool? = nil

    /// Whether anything at all is selected. When nothing is, Nivli fails open and shields
    /// nothing (see `ShieldPolicy`).
    var hasSelection: Bool {
        if let override = selectionOverrideForTesting { return override }
        return !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    /// The counts behind "N apps · M categories · W sites".
    var selectionSummary: (apps: Int, categories: Int, sites: Int) {
        (
            apps: selection.applicationTokens.count,
            categories: selection.categoryTokens.count,
            sites: selection.webDomainTokens.count
        )
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case onboardingComplete
        case selection
        case minimumMinutes
        case weeklyRestDays
        case oneOffRestDays
        case workouts
        case entitlementValidUntil
        case healthEnabled
        case reminderEnabled
        case reminderMinutesFromMidnight
        case goals
        case currentFrequency
        case dailyPhoneHours
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = NivliState()
        onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete)
            ?? defaults.onboardingComplete
        selection = try container.decodeIfPresent(FamilyActivitySelection.self, forKey: .selection)
            ?? defaults.selection
        minimumMinutes = try container.decodeIfPresent(Int.self, forKey: .minimumMinutes)
            ?? defaults.minimumMinutes
        weeklyRestDays = try container.decodeIfPresent(Set<Int>.self, forKey: .weeklyRestDays)
            ?? defaults.weeklyRestDays
        oneOffRestDays = try container.decodeIfPresent(Set<DayKey>.self, forKey: .oneOffRestDays)
            ?? defaults.oneOffRestDays
        workouts = try container.decodeIfPresent([WorkoutEntry].self, forKey: .workouts)
            ?? defaults.workouts
        entitlementValidUntil = try container.decodeIfPresent(Date.self, forKey: .entitlementValidUntil)
        healthEnabled = try container.decodeIfPresent(Bool.self, forKey: .healthEnabled)
            ?? defaults.healthEnabled
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled)
            ?? defaults.reminderEnabled
        reminderMinutesFromMidnight = try container
            .decodeIfPresent(Int.self, forKey: .reminderMinutesFromMidnight)
            ?? defaults.reminderMinutesFromMidnight
        goals = try container.decodeIfPresent([Goal].self, forKey: .goals) ?? defaults.goals
        currentFrequency = try container.decodeIfPresent(Frequency.self, forKey: .currentFrequency)
        dailyPhoneHours = try container.decodeIfPresent(PhoneHours.self, forKey: .dailyPhoneHours)
        selectionOverrideForTesting = nil
    }
}

extension NivliState {
    /// A copy with one thing changed, without mutating the receiver.
    ///
    /// `SharedStore.update(_:)` takes an `inout` closure for convenience at the call site;
    /// this is the value-level equivalent for code that holds a state and wants a new one.
    func with(_ change: (inout NivliState) -> Void) -> NivliState {
        var copy = self
        change(&copy)
        return copy
    }

    /// A copy whose workouts are sorted oldest first, which every other helper assumes.
    func sortedWorkouts() -> NivliState {
        with { $0.workouts.sort { $0.start < $1.start } }
    }
}
