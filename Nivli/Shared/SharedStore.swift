import Foundation
import os

/// The only reader and writer of Nivli's stored state.
///
/// The state lives in one JSON file inside the App Group container, so the app, the
/// DeviceActivity monitor and the shield extension all read the same bytes. A file rather
/// than `UserDefaults` for one reason: the workouts in it can come from Apple Health, and
/// Apple's HealthKit terms forbid putting Health data anywhere iCloud will copy it. The file
/// is therefore marked *excluded from backup* every time it is written, and protected until
/// the iPhone has been unlocked once after a restart (the midnight extension runs after that).
///
/// Nothing in this type can fail loudly: a missing App Group falls back to the app's own
/// Application Support folder, and unreadable data reads as a fresh `NivliState`.
final class SharedStore: @unchecked Sendable {
    /// The instance the app and both extensions use.
    static let shared = SharedStore()

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "store")

    /// - Parameter directory: where the state file lives. Tests pass a throw-away folder.
    ///   The default is the App Group container, or Application Support when the group is
    ///   unavailable (a missing entitlement), so the app still runs.
    init(directory: URL? = nil) {
        let folder = directory ?? Self.defaultDirectory()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        self.fileURL = folder.appendingPathComponent(SharedConstants.stateFileName)

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
        guard let data = try? Data(contentsOf: fileURL) else { return NivliState() }
        do {
            return try decoder.decode(NivliState.self, from: data)
        } catch {
            logger.error("State could not be decoded, falling back to defaults: \(error.localizedDescription, privacy: .public)")
            return NivliState()
        }
    }

    /// Writes the state atomically. A failure is logged and leaves the previous value in
    /// place, which is the safest outcome: stale state fails open, missing state does not.
    func save(_ state: NivliState) {
        do {
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: Self.writeOptions)
            excludeFromBackup()
        } catch {
            logger.error("State could not be written, keeping the previous value: \(error.localizedDescription, privacy: .public)")
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
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private static func defaultDirectory() -> URL {
        let manager = FileManager.default
        if let container = manager.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.appGroupID) {
            return container
        }
        let support = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? manager.temporaryDirectory
        return support.appendingPathComponent("Nivli", isDirectory: true)
    }

    private static var writeOptions: Data.WritingOptions {
        #if os(iOS)
        return [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        #else
        return [.atomic]
        #endif
    }

    /// Health data must never reach iCloud; the flag is re-applied on every write because an
    /// atomic write replaces the file.
    private func excludeFromBackup() {
        var url = fileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            logger.error("Backup exclusion could not be set: \(error.localizedDescription, privacy: .public)")
        }
    }
}
