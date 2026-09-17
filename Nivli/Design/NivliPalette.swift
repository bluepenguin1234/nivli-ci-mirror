import SwiftUI
import UIKit

/// Nivli's canvas and surfaces, compiled into the app and the widgets alike: the night
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
}

/// The canvas itself: a soft glow centred just above the middle — the brand page's
/// `radial-gradient(88% 46% at 50% 38%, #10242F, #08131C 72%)` — or its daylight twin.
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

extension View {
    /// Puts a screen on the canvas: a List or Form loses its own grey, the canvas paints
    /// edge to edge behind it, and the navigation bar stays clear over it.
    func nivliScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(NivliCanvas().ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// A sheet on the canvas, edge to edge.
    func nivliSheet() -> some View {
        self
            .scrollContentBackground(.hidden)
            .presentationBackground { NivliCanvas() }
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
