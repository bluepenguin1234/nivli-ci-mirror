import UIKit

/// The two taps Nivli ever plays.
///
/// A light impact on every forward step, so moving through onboarding feels like turning a
/// page, and one success notification when a purchase or a restore lands. Both generators
/// are created at the call site rather than kept around: the system prepares them lazily and
/// a stale generator is the usual reason a haptic arrives late.
@MainActor
enum Haptics {
    /// A forward step: Continue, a page turn, a confirmed choice.
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Something landed: the subscription started, or a purchase was restored.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
