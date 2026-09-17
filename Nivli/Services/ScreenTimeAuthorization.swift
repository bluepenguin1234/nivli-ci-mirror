import Foundation
import FamilyControls
import Observation
import os

/// Screen Time permission, which is the one thing Nivli genuinely cannot work without.
///
/// A refusal or an unavailable device is never fatal: the status simply says so and the
/// screens explain it. The app still logs workouts, still counts streaks, and shields
/// nothing — the same fail-open position `ShieldPolicy` takes.
@MainActor
@Observable
final class ScreenTimeAuthorization {
    /// Where permission stands. `.unavailable` carries the sentence to show the person.
    enum Status: Equatable {
        case notDetermined
        case approved
        case denied
        case unavailable(String)
    }

    private(set) var status: Status = .notDetermined
    private(set) var isRequesting: Bool = false

    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "screen-time")

    init() {
        refresh()
    }

    /// Reads the system's current answer. Cheap; call it on every foreground.
    func refresh() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            status = .notDetermined
        case .denied:
            status = .denied
        case .approved:
            status = .approved
        @unknown default:
            status = .unavailable(Self.unavailableMessage)
        }
    }

    /// Asks iOS for permission for this person's own device. Shows the system sheet once;
    /// afterwards it resolves immediately from whatever was chosen then.
    ///
    /// A refusal throws rather than returning, and leaves the system status at
    /// `.notDetermined`, so the answer is read back from the system either way and a
    /// still-undecided status after the sheet has been through is recorded as the denial it
    /// is. That is what puts "Allow Screen Time" and the explanation on screen instead of a
    /// button that silently does nothing. The error itself is only ever logged: an Apple
    /// error string tells the person nothing they can act on.
    func request() async {
        isRequesting = true
        defer { isRequesting = false }
        #if targetEnvironment(simulator)
        var isUnavailable = false
        #endif
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            logger.error("Screen Time authorization failed: \(error.localizedDescription, privacy: .public)")
            #if targetEnvironment(simulator)
            isUnavailable = true
            #endif
        }
        refresh()
        #if targetEnvironment(simulator)
        if isUnavailable {
            status = .unavailable(Self.unavailableMessage)
        }
        #else
        if case .notDetermined = status {
            status = .denied
        }
        #endif
    }

    /// The sentence for a device that cannot do this at all — which in practice means the
    /// simulator, where Screen Time is not implemented.
    private static let unavailableMessage =
        "Screen Time isn't available on this device. On an iPhone it takes one tap."
}
