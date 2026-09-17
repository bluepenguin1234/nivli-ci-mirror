import SwiftUI
import UIKit

/// Nivli's canvas and surfaces, used by every screen: the night
/// navy with a soft glow behind what matters, or its daylight twin when the person chose
/// Light; rows and cards a shade lighter than the canvas. No system grey and no pure
/// black anywhere in the app — every screen sits on this.
enum NivliPalette {
    // Night, from the brand page.
    static let nightGlow = UIColor(red: 0x10 / 255, green: 0x24 / 255, blue: 0x2F / 255, alpha: 1)
    static let nightEdge = UIColor(red: 0x08 / 255, green: 0x13 / 255, blue: 0x1C / 255, alpha: 1)
    static let nightSurface = UIColor(red: 0x10 / 255, green: 0x20 / 255, blue: 0x2B / 255, alpha: 1)
    static let nightRaised = UIColor(red: 0x16 / 255, green: 0x2B / 255, blue: 0x3B / 255, alpha: 1)
    static let nightDisc = UIColor(red: 0x14 / 255, green: 0x29 / 255, blue: 0x3A / 255, alpha: 1)

    // Day: the same shapes in pale mint-grey and white.
    static let dayGlow = UIColor(red: 0xF3 / 255, green: 0xF8 / 255, blue: 0xF7 / 255, alpha: 1)
    static let dayEdge = UIColor(red: 0xE4 / 255, green: 0xEC / 255, blue: 0xEE / 255, alpha: 1)
    static let daySurface = UIColor.white
    static let dayRaised = UIColor(red: 0xF0 / 255, green: 0xF5 / 255, blue: 0xF6 / 255, alpha: 1)
    static let dayDisc = UIColor(red: 0xDC / 255, green: 0xE7 / 255, blue: 0xEA / 255, alpha: 1)

    // The two lights behind every screen. Neither is ever a control colour: the brand mint
    // reads as warmth, the cool violet only keeps the canvas from going flat.
    static let lightMint = UIColor(red: 0x5E / 255, green: 0xDC / 255, blue: 0xC0 / 255, alpha: 1)
    static let lightViolet = UIColor(red: 0x7C / 255, green: 0x6C / 255, blue: 0xF6 / 255, alpha: 1)

    /// A colour that follows the appearance the view is drawn in.
    static func adaptive(night: UIColor, day: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? night : day })
    }
}

extension Color {
    /// The flat canvas colour, for the places a gradient cannot go: a toolbar, a widget's
    /// fallback, the strip behind a keyboard.
    static let nivliCanvas = NivliPalette.adaptive(night: NivliPalette.nightEdge, day: NivliPalette.dayEdge)
    /// A row in a list, or a card on the canvas.
    static let nivliSurface = NivliPalette.adaptive(night: NivliPalette.nightSurface, day: NivliPalette.daySurface)
    /// A surface that sits on top of another: a bar over a sheet, a chip on a card.
    static let nivliRaised = NivliPalette.adaptive(night: NivliPalette.nightRaised, day: NivliPalette.dayRaised)
    /// The disc behind the mark.
    static let nivliDisc = NivliPalette.adaptive(night: NivliPalette.nightDisc, day: NivliPalette.dayDisc)
    /// A hairline between rows or around a card.
    static let nivliLine = NivliPalette.adaptive(night: UIColor.white.withAlphaComponent(0.08), day: UIColor.black.withAlphaComponent(0.08))
    /// The lit end of the accent. Only ever used inside a gradient, so a stroke carries a
    /// highlight instead of one flat colour. Still the accent family: one accent, two values.
    static let nivliAccentHighlight = NivliPalette.adaptive(
        night: UIColor(red: 0xA9 / 255, green: 0xF3 / 255, blue: 0xE2 / 255, alpha: 1),
        day: UIColor(red: 0x2E / 255, green: 0xA8 / 255, blue: 0x94 / 255, alpha: 1)
    )
}

/// The canvas itself: a soft glow centred just above the middle — the brand page's
/// `radial-gradient(88% 46% at 50% 38%, #10242F, #08131C 72%)` — or its daylight twin.
/// Kept flat and cheap, for the launch screen and anywhere a background must not move.
struct NivliCanvas: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let night = colorScheme == .dark
        EllipticalGradient(
            stops: [
                .init(color: Color(uiColor: night ? NivliPalette.nightGlow : NivliPalette.dayGlow), location: 0),
                .init(color: Color(uiColor: night ? NivliPalette.nightEdge : NivliPalette.dayEdge), location: 0.72),
            ],
            center: UnitPoint(x: 0.5, y: 0.38),
            startRadiusFraction: 0,
            endRadiusFraction: 0.62
        )
    }
}

/// The canvas with two lights on it: mint from the upper left, a cool violet from the lower
/// right, both blurred far past their own edges so neither ever reads as a circle. This is
/// what gives a screen depth, and what gives a glass card something to refract — a material
/// over one flat colour is just a tint.
///
/// Night carries the light. Day only hints at it, because a bright orb under a glass card
/// takes the contrast out of the text sitting on it.
struct NivliGlow: View {
    @Environment(\.colorScheme) private var colorScheme

    private static let blur: CGFloat = 80

    private var mintOpacity: Double { colorScheme == .dark ? 0.18 : 0.07 }
    private var violetOpacity: Double { colorScheme == .dark ? 0.10 : 0.05 }

    var body: some View {
        NivliCanvas()
            .overlay {
                GeometryReader { proxy in
                    let span = max(proxy.size.width, proxy.size.height)
                    ZStack {
                        orb(Color(uiColor: NivliPalette.lightMint), opacity: mintOpacity, diameter: span * 0.9)
                            .position(x: proxy.size.width * 0.14, y: proxy.size.height * 0.14)
                        orb(Color(uiColor: NivliPalette.lightViolet), opacity: violetOpacity, diameter: span * 0.8)
                            .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.84)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }

    private func orb(_ color: Color, opacity: Double, diameter: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: diameter, height: diameter)
            .blur(radius: Self.blur)
    }
}

extension View {
    /// Puts a screen on the canvas: a List or Form loses its own grey, the lit canvas paints
    /// edge to edge behind it, and the navigation bar stays clear over it.
    func nivliScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(NivliGlow().ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// A sheet on the canvas, edge to edge.
    func nivliSheet() -> some View {
        self
            .scrollContentBackground(.hidden)
            .presentationBackground { NivliGlow() }
    }

    /// A row that sits on the canvas as a surface. Apply to a `Section`'s content or to a
    /// single row; rows that should be bare (a mark, a footer note) stay `.clear`.
    func nivliRow() -> some View {
        listRowBackground(Color.nivliSurface)
    }

    /// A card on the canvas: the surface colour with the app's corner radius.
    func nivliCard(cornerRadius: CGFloat = 14) -> some View {
        background(Color.nivliSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension NivliPalette {
    /// The one control SwiftUI cannot recolour by itself: the segmented picker's track and
    /// knob are UIKit's, so they are told the surface colours once, at launch, through the
    /// appearance proxy. Dynamic colours, so Light and Dark both follow the canvas.
    static func styleSystemControls() {
        let control = UISegmentedControl.appearance()
        control.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? nightSurface : dayRaised }
        control.selectedSegmentTintColor = UIColor { $0.userInterfaceStyle == .dark ? nightRaised : daySurface }
        control.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
    }
}
