import SwiftUI
import UIKit

/// Nivli's visual language: the lit brand canvas and its surfaces (NivliPalette.swift), glass
/// over that canvas rather than a system grey; one accent (mint by night, teal by day) used as
/// light as well as colour; rounded numerals for counts, monospaced small caps for readings;
/// restraint everywhere else.
enum Theme {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let stackSpacing: CGFloat = 16

    /// The brand ink and mint, for places that must not adapt to the appearance
    /// (the celebration, the ring's fill).
    static let ink = Color(red: 0x14 / 255, green: 0x2B / 255, blue: 0x39 / 255)
    static let mint = Color(red: 0x5E / 255, green: 0xDC / 255, blue: 0xC0 / 255)

    // MARK: - Glass

    /// A glass pane's radius. Larger than a solid card's, because a translucent edge needs
    /// more curve before it reads as a pane rather than a box.
    static let glassRadius: CGFloat = 20

    /// The hairline that gives a glass pane its edge: white at 8% by night, ink at 6% by day.
    /// Without it the pane's boundary dissolves into whatever is behind it.
    static let glassStroke = NivliPalette.adaptive(
        night: UIColor.white.withAlphaComponent(0.08),
        day: UIColor.black.withAlphaComponent(0.06)
    )

    // MARK: - Telemetry

    /// Small uppercase monospaced type: the label a machine would print above a reading.
    /// Used for "TODAY", "DAY STREAK", "MONTHLY" — never for a sentence.
    static let telemetry: Font = .caption2.weight(.semibold).monospaced()

    /// All-caps at caption size needs letter-spacing to stop the words clotting. The only
    /// register in the app that is ever tracked; prose never is.
    static let telemetryTracking: CGFloat = 1.2

    // MARK: - Light

    /// A soft light behind one hero element — a ring, a numeral, a price, a disc. Never
    /// behind body text, and never behind a whole card: a lit card is a glowing rectangle.
    static func glow(_ color: Color = .accentColor, radius: CGFloat = 24) -> NivliGlowModifier {
        NivliGlowModifier(color: color, radius: radius)
    }

    /// Day never carries more than a hint of light. 8% is the ceiling in Light mode, so a
    /// glow can never wash out the text it sits behind.
    static func glowOpacity(_ night: Double, in scheme: ColorScheme) -> Double {
        scheme == .dark ? night : min(night, 0.08)
    }

    /// A number that changes (the streak, minutes) — rounded and monospaced so it never jitters.
    static func numeral(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight).monospacedDigit()
    }
}

/// The accent used as light rather than as paint. Built through `Theme.glow(_:)` so the
/// Light-mode ceiling is applied in one place instead of at every call site.
struct NivliGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(Theme.glowOpacity(0.35, in: colorScheme)), radius: radius)
    }
}

/// A telemetry label: uppercase, monospaced, tracked, quiet. VoiceOver is handed the original
/// words, so "DAY STREAK" is never spelled out one letter at a time.
struct TelemetryLabel: View {
    let text: String
    var tint: Color = .secondary

    init(_ text: String, tint: Color = .secondary) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.telemetry)
            .tracking(Theme.telemetryTracking)
            .foregroundStyle(tint)
            .accessibilityLabel(text)
    }
}

/// How Nivli looks. Dark is the default because it matches the app icon; "Match iPhone"
/// hands the choice back to iOS Settings.
enum AppearanceSetting: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    static let key = "nivli.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "Match iPhone"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

/// A large primary action: the accent, full width, 54 points tall, lit from above and
/// sitting in its own pool of accent light.
struct ProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        return configuration.label
            .font(.headline)
            // The canvas colour on the accent: navy on mint by night, pale on teal by day.
            .foregroundStyle(Color.nivliCanvas)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(Color.accentColor.opacity(isEnabled ? 1 : 0.4), in: shape)
            // A lighter line along the top edge only: the light in the room falls from above,
            // which is the whole of the depth here. No bevel, no inner shadow.
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(isEnabled ? 0.3 : 0), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .shadow(
                color: Color.accentColor.opacity(isEnabled ? Theme.glowOpacity(0.3, in: colorScheme) : 0),
                radius: 18,
                y: 6
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// A secondary action that sits next to a prominent one.
struct QuietButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// A text-only action under a prominent one ("Not now", "Restore Purchases").
struct PlainLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == ProminentButtonStyle {
    static var prominent: ProminentButtonStyle { ProminentButtonStyle() }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}

extension ButtonStyle where Self == PlainLinkButtonStyle {
    static var plainLink: PlainLinkButtonStyle { PlainLinkButtonStyle() }
}
