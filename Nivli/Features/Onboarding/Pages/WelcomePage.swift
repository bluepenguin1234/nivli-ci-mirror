import SwiftUI

/// Page 1. The mark breathing inside its own pool of mint light, and the positioning line,
/// with nothing to answer: the first screen asks for nothing so the first tap costs nothing.
struct WelcomePage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var isBreathing = false

    /// The headline is the loudest type in the app, and the orb behind the mark is sized to
    /// it, so both follow the text size the person chose.
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var orbSize: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            NivliMark(height: 104)
                .scaleEffect(isBreathing ? 1.04 : 1)
                .animation(breath, value: isBreathing)
                // A background, not a stacked view: the orb is twice the mark's height and
                // must not push the headline down the page to make room for itself.
                .background { orb }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 48)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                Text("Move first.\nThen scroll.")
                    .font(.system(size: headlineSize, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("Nivli keeps the apps you choose locked until you have worked out today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Log it in two taps, or let Apple Health prove it for you.")
                    .font(.body)
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

    /// The light the mark sits in. Decorative only, so it is hidden from VoiceOver.
    private var orb: some View {
        Circle()
            .fill(Theme.mint.opacity(Theme.glowOpacity(0.25, in: colorScheme)))
            .frame(width: orbSize, height: orbSize)
            .blur(radius: 60)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// A slow in-and-out, close to a resting breath. `nil` under reduce motion, which stops
    /// the animation from ever starting rather than freezing it mid-scale.
    private var breath: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    }
}
