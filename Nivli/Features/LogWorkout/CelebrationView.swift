import Foundation
import SwiftUI

/// The two seconds after a workout lands. A check springs in inside its own light, one ring
/// expands away from it, the streak reads big, and a milestone brings confetti. Tapping
/// anywhere gets out of the way.
struct CelebrationView: View {
    let result: LogResult
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasArrived = false
    @State private var hasPulsed = false

    /// The check and the disc behind it follow the person's text size, so the celebration
    /// reads the same at every Dynamic Type setting.
    @ScaledMetric(relativeTo: .largeTitle) private var checkSize: CGFloat = 58
    @ScaledMetric(relativeTo: .largeTitle) private var discSize: CGFloat = 132

    private static let pieceCount = 40

    var body: some View {
        ZStack {
            Theme.ink.opacity(0.92)
                .ignoresSafeArea()
            if showsConfetti {
                Confetti(pieceCount: Self.pieceCount, hasFallen: hasArrived)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            content
        }
        .contentShape(Rectangle())
        .onTapGesture { onDone() }
        .onAppear(perform: arrive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onDone() }
    }

    private var content: some View {
        VStack(spacing: 18) {
            ZStack {
                pulse
                Circle()
                    .fill(Theme.mint.opacity(0.16))
                    .frame(width: discSize, height: discSize)
                    // This screen is always dark, whatever the appearance, so the light on it
                    // is the full 35% rather than the Light-mode ceiling.
                    .shadow(color: Theme.mint.opacity(0.35), radius: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: checkSize, weight: .bold))
                    .foregroundStyle(Theme.mint)
            }
            .scaleEffect(hasArrived ? 1 : 0.6)
            .opacity(hasArrived ? 1 : 0)

            Text("Unlocked.")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text("\(result.streak)-day streak")
                .font(Theme.numeral(.title2))
                .foregroundStyle(.white.opacity(0.85))

            if let milestone = result.milestone {
                Text("\(milestone) days!")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.mint)
            }
        }
        .padding(.horizontal, Theme.screenPadding)
    }

    /// One ring travelling outwards and fading, over 1.2 seconds, once. Nothing repeats, and
    /// under reduce motion it is never drawn at all.
    @ViewBuilder
    private var pulse: some View {
        if !reduceMotion {
            Circle()
                .strokeBorder(Theme.mint.opacity(hasPulsed ? 0 : 0.45), lineWidth: 2)
                .frame(width: discSize, height: discSize)
                .scaleEffect(hasPulsed ? 1.7 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var showsConfetti: Bool {
        result.milestone != nil && !reduceMotion
    }

    private var spokenSummary: String {
        var parts = ["Unlocked.", "\(result.streak) day streak."]
        if let milestone = result.milestone {
            parts.append("\(milestone) days reached.")
        }
        parts.append("Tap to dismiss.")
        return parts.joined(separator: " ")
    }

    private func arrive() {
        guard !reduceMotion else {
            hasArrived = true
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            hasArrived = true
        }
        withAnimation(.easeOut(duration: 1.2)) {
            hasPulsed = true
        }
    }
}

/// A light shower of rounded rectangles. Deterministic: every piece's position, tint and
/// delay come from its index, so a redraw never reshuffles the sky.
private struct Confetti: View {
    let pieceCount: Int
    let hasFallen: Bool

    private static let tints: [Color] = [Theme.mint, .white, .accentColor]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack(alignment: .top) {
                ForEach(0..<pieceCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Self.tints[index % Self.tints.count])
                        .frame(width: 6, height: 12)
                        .rotationEffect(.degrees(noise(index, salt: 3) * 360))
                        .opacity(0.9)
                        .position(
                            x: noise(index, salt: 1) * width,
                            y: hasFallen ? height + 60 : -60
                        )
                        .animation(
                            .easeIn(duration: 1.6).delay(noise(index, salt: 2) * 0.6),
                            value: hasFallen
                        )
                }
            }
        }
    }

    /// A stable pseudo-random number in 0..<1 for a piece, without any stored state.
    private func noise(_ index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 127 + salt * 311)) * 43_758.545_3
        return value - value.rounded(.down)
    }
}
