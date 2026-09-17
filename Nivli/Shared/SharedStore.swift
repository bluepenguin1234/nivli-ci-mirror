import Foundation
import os

/// The only reader and writer of the App Group defaults.
///
/// The app, the DeviceActivity monitor and the shield extension all go through this, so the
/// encoding, the key and the failure behaviour live in exactly one place. `UserDefaults` is
/// itself thread-safe and nothing is cached here, so a write from the app is visible to an
/// extension the next time it loads — which is all the coordination Nivli needs.
///
/// Nothing in this type can fail loudly: a missing App Group falls back to
/// `UserDefaults.standard`, and unreadable data reads as a fresh `NivliState`.
final class SharedStore: @unchecked Sendable {
    /// The instance the app and both extensions use.
    static let shared = SharedStore()

    private let defaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "store")

    /// - Parameter suiteName: the App Group to read and write. Tests pass a throw-away name.
    ///   If the suite cannot be opened — a missing entitlement, or a reserved name — the
    ///   store quietly uses `UserDefaults.standard` so the app still runs.
    init(suiteName: String = SharedConstants.appGroupID) {
        if let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        self.key = SharedConstants.stateKey

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// The stored state, or a fresh default one if nothing is stored or the data is
    /// unreadable. Never throws, never returns `nil`.
    func load() -> NivliState {
        guard let data = defaults.data(forKey: key) else { return NivliState() }
        do {
            return try decoder.decode(NivliState.self, from: data)
        } catch {
            logger.error("State could not be decoded, falling back to defaults: \(error.localizedDescription, privacy: .public)")
            return NivliState()
        }
    }

    /// Writes the state. A failure to encode is logged and leaves the previous value in
    /// place, which is the safest outcome: stale state fails open, missing state does not.
    func save(_ state: NivliState) {
        do {
            let data = try encoder.encode(state)
            defaults.set(data, forKey: key)
        } catch {
            logger.error("State could not be encoded, keeping the previous value: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Load, change, save — and hand back what was saved.
    ///
    /// The closure takes the state `inout` purely for call-site comfort; the stored value is
    /// still replaced wholesale, so callers never share a mutable reference.
    @discardableResult
    func update(_ change: (inout NivliState) -> Void) -> NivliState {
        var state = load()
        change(&state)
        save(state)
        return state
    }

    /// Forgets everything. Used by tests and by "delete my data" in Settings.
    func reset() {
        defaults.removeObject(forKey: key)
    }
}
