import SwiftUI

/// The ring at the top of Home: the one thing a person should be able to read across the
/// room. A hairline track, a thick accent arc that fills when the day is won and carries its
/// own light, and a symbol in the middle that says the same thing a second way.
struct StatusHero: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: CGFloat = 0

    /// The ring and its symbol grow with the person's text size; the stroke stays put so a
    /// large ring does not turn into a solid disc.
    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 200
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 62

    /// The track is a hairline and the arc is heavy: the contrast between them is what makes
    /// the ring readable at a glance, not the colour.
    private static let trackWidth: CGFloat = 1
    private static let arcWidth: CGFloat = 16

    var body: some View {
        VStack(spacing: 22) {
            ring
            VStack(spacing: 6) {
                TelemetryLabel(reading)
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { settle() }
        .onChange(of: targetProgress) { _, _ in settle() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.nivliLine, lineWidth: Self.trackWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(arc, style: StrokeStyle(lineWidth: Self.arcWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .modifier(Theme.glow(.accentColor, radius: 28))
            Image(systemName: symbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(isWon ? Color.accentColor : Color.secondary)
        }
        .frame(width: diameter, height: diameter)
    }

    /// The arc is lit rather than flat: the accent turns through its lighter value and back,
    /// so the stroke has a highlight where the day has got to. Still one accent, two values.
    private var arc: AngularGradient {
        AngularGradient(
            colors: [Color.accentColor, Color.nivliAccentHighlight, Color.accentColor],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    // MARK: - Copy

    /// The one-word reading above the title, in the register a meter would use.
    private var reading: String {
        switch model.decision {
        case .locked: return "Locked"
        case .open(.workedOut): return "Unlocked"
        case .open(.restDay), .open(.notSubscribed), .open(.nothingSelected), .open(.notOnboarded):
            return "Today"
        }
    }

    private var title: String {
        switch model.decision {
        case .locked: return "Locked until you move"
        case .open(.workedOut): return "Unlocked for today"
        case .open(.restDay): return "Rest day"
        case .open(.notSubscribed): return "Subscription ended"
        case .open(.nothingSelected), .open(.notOnboarded): return "No apps chosen"
        }
    }

    private var detail: String {
        switch model.decision {
        case .locked: return waitingLine
        case .open(.workedOut(let entry)): return "\(entry.summary) · \(entry.sourceLabel)"
        case .open(.restDay): return "Nothing is locked today"
        case .open(.notSubscribed): return "Your apps are not locked"
        case .open(.nothingSelected), .open(.notOnboarded): return "Pick the apps that should wait"
        }
    }

    /// "3 apps are waiting" when Nivli can count them, and the vaguer line when the
    /// selection is categories or sites rather than named apps.
    private var waitingLine: String {
        let summary = model.state.selectionSummary
        switch summary.apps {
        case 0: return "Your chosen apps are waiting"
        case 1: return "1 app is waiting"
        default: return "\(summary.apps) apps are waiting"
        }
    }

    private var symbolName: String {
        switch model.decision {
        case .locked: return "lock.fill"
        case .open(.workedOut): return "checkmark"
        case .open(.restDay): return "leaf.fill"
        case .open(.notSubscribed), .open(.nothingSelected), .open(.notOnboarded): return "lock.open"
        }
    }

    // MARK: - The arc

    /// The ring only fills for a day that is actually won or deliberately rested. A day
    /// that is open because nothing is set up stays empty, so an empty ring never reads
    /// as an achievement.
    private var isWon: Bool {
        switch model.decision {
        case .open(.workedOut), .open(.restDay): return true
        case .locked, .open(.notSubscribed), .open(.nothingSelected), .open(.notOnboarded): return false
        }
    }

    private var targetProgress: CGFloat {
        isWon ? 1 : 0
    }

    private func settle() {
        guard !reduceMotion else {
            progress = targetProgress
            return
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
            progress = targetProgress
        }
    }
}
