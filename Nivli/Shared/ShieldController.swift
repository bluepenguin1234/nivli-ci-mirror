import Foundation
import FamilyControls
import ManagedSettings
import os

/// The thin layer between `ShieldPolicy`'s answer and the system's shields.
///
/// Everything goes through one *named* `ManagedSettingsStore`, so `clear()` can safely wipe
/// the whole store without touching settings any other app or profile put on the device.
/// Nivli never learns what is inside the selection: the tokens are opaque and the system
/// renders the names.
struct ShieldController {
    private let store: ManagedSettingsStore
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "shield")

    init(
        store: ManagedSettingsStore = ManagedSettingsStore(
            named: ManagedSettingsStore.Name(SharedConstants.managedSettingsStoreName)
        )
    ) {
        self.store = store
    }

    /// Shields exactly what the person picked. An empty part of the selection is written as
    /// `nil` rather than an empty set, which is how ManagedSettings spells "shield nothing
    /// of this kind".
    func apply(_ selection: FamilyActivitySelection) {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        let webDomains = selection.webDomainTokens

        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        store.shield.webDomainCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy<WebDomain>.specific(categories)
    }

    /// Removes every shield Nivli put on. Called whenever the decision is `.open`, and on
    /// sign-out style events such as an expired subscription.
    func clear() {
        store.clearAllSettings()
    }

    /// Load the shared state, ask `ShieldPolicy`, then apply or clear. Returns the decision
    /// so the caller can show the matching screen.
    ///
    /// This is the one entry point the app uses on every foreground and the DeviceActivity
    /// monitor uses at the start and end of every day.
    @discardableResult
    func refresh(sharedStore: SharedStore = .shared, now: Date = Date()) -> ShieldDecision {
        let state = sharedStore.load()
        let decision = ShieldPolicy.decision(state, now: now)
        switch decision {
        case .locked:
            apply(state.selection)
        case .open:
            clear()
        }
        logger.log("Shield refresh: \(Self.label(for: decision), privacy: .public)")
        return decision
    }

    /// A short, identifier-free word for the log. Never includes a workout id or anything
    /// about which apps were picked.
    private static func label(for decision: ShieldDecision) -> String {
        switch decision {
        case .locked: return "locked"
        case .open(.notSubscribed): return "open/notSubscribed"
        case .open(.notOnboarded): return "open/notOnboarded"
        case .open(.nothingSelected): return "open/nothingSelected"
        case .open(.restDay): return "open/restDay"
        case .open(.workedOut): return "open/workedOut"
        }
    }
}
