import SwiftUI

/// Nivli's visual language: the brand canvas and its surfaces (NivliPalette.swift), never a
/// system grey or a material; one accent (mint by night, teal by day); rounded numerals for
/// counts; restraint everywhere else.
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

    /// A number that changes (the streak, minutes) — rounded and monospaced so it never jitters.
    static func numeral(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight).monospacedDigit()
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

/// A large primary action: the accent, full width, 54 points tall.
struct ProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            // The canvas colour on the accent: navy on mint by night, pale on teal by day.
            .foregroundStyle(Color.nivliCanvas)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(Color.accentColor.opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
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
