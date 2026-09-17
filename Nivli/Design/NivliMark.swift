import SwiftUI

/// The "Ni" mark: the N stroke whose right leg stops short, completed by the mint dot.
/// Drawn from the icon's own geometry (Brand/Nivli-Icon.svg, 1024 grid) so it stays crisp
/// at any size, and coloured for light and dark mode. The dot can carry one state: a ring
/// when something is overdue, as on the brand sheet's "Reminder due" variant.
struct NivliMark: View {
    enum State: Equatable {
        case plain
        case attention
    }

    var state: State = .plain
    var height: CGFloat = 26

    @Environment(\.colorScheme) private var colorScheme

    static let ink = Color(red: 0x14 / 255, green: 0x2B / 255, blue: 0x39 / 255)
    static let mint = Color(red: 0x5E / 255, green: 0xDC / 255, blue: 0xC0 / 255)

    // The box on the 1024 icon grid that holds the N, the dot and the attention ring.
    private static let gridMinX: CGFloat = 256
    private static let gridMinY: CGFloat = 218
    private static let gridWidth: CGFloat = 556
    private static let gridHeight: CGFloat = 532

    var body: some View {
        Canvas { context, size in
            let scale = size.height / Self.gridHeight
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: (x - Self.gridMinX) * scale, y: (y - Self.gridMinY) * scale)
            }
            func circle(centerX: CGFloat, centerY: CGFloat, radius: CGFloat) -> Path {
                let origin = point(centerX - radius, centerY - radius)
                return Path(ellipseIn: CGRect(x: origin.x, y: origin.y, width: radius * 2 * scale, height: radius * 2 * scale))
            }

            var stroke = Path()
            stroke.move(to: point(302, 704))
            stroke.addLine(to: point(302, 312))
            stroke.addLine(to: point(718, 704))
            stroke.addLine(to: point(718, 432))
            let ink: Color = colorScheme == .dark ? .white : Self.ink
            context.stroke(stroke, with: .color(ink), style: StrokeStyle(lineWidth: 92 * scale, lineCap: .round, lineJoin: .round))

            context.fill(circle(centerX: 718, centerY: 312, radius: 50), with: .color(Self.mint))
            if state == .attention {
                context.stroke(circle(centerX: 718, centerY: 312, radius: 82), with: .color(Self.mint), style: StrokeStyle(lineWidth: 16 * scale))
            }
        }
        .frame(width: height * Self.gridWidth / Self.gridHeight, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state == .attention ? "Nivli. Something is overdue." : "Nivli")
        .accessibilityAddTraits(.isHeader)
    }
}
