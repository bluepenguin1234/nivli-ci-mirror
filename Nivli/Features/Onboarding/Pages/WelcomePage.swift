import SwiftUI

/// Page 1. The mark breathing on the night canvas and the positioning line, with nothing to
/// answer: the first screen asks for nothing so the first tap costs nothing.
struct WelcomePage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            NivliMark(height: 104)
                .scaleEffect(isBreathing ? 1.04 : 1)
                .animation(breath, value: isBreathing)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 48)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                Text("Move first.\nThen scroll.")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("Nivli keeps the apps you choose locked until you have worked out today.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Log it in two taps, or let Apple Health prove it for you.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            guard !reduceMotion else { return }
            isBreathing = true
        }
    }

    /// A slow in-and-out, close to a resting breath. `nil` under reduce motion, which stops
    /// the animation from ever starting rather than freezing it mid-scale.
    private var breath: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    }
}
