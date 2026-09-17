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
    func request() async {
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refresh()
        } catch {
            logger.error("Screen Time authorization failed: \(error.localizedDescription, privacy: .public)")
            #if targetEnvironment(simulator)
            status = .unavailable(Self.unavailableMessage)
            #else
            status = .unavailable(error.localizedDescription)
            #endif
        }
    }

    /// The sentence for a device that cannot do this at all — which in practice means the
    /// simulator, where Screen Time is not implemented.
    private static let unavailableMessage =
        "Screen Time isn't available on this device. On an iPhone it takes one tap."
}
