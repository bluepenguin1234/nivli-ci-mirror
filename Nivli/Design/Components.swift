import SwiftUI

/// A card on the canvas: the surface colour, the app's corner radius, a hairline.
struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = Theme.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.nivliSurface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).strokeBorder(Color.nivliLine))
    }
}

/// A large title with an optional line under it, left-aligned, for the top of a page.
struct PageHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A selectable row: a symbol, a title, an optional line, and a check when chosen.
struct ChoiceRow: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .frame(width: 28)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.semibold))
                    if let subtitle {
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.nivliLine)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.nivliSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.nivliLine, lineWidth: isSelected ? 1.5 : 1)
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A thin progress bar for the onboarding pages.
struct StepProgressBar: View {
    let step: Int
    let total: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.nivliLine)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: proxy.size.width * CGFloat(max(0, min(step, total))) / CGFloat(max(total, 1)))
            }
        }
        .frame(height: 4)
        .animation(.easeOut(duration: 0.3), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of \(total)")
    }
}

/// Small rounded label used for counts and states.
struct Chip: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = .secondary

    var body: some View {
        Group {
            if let systemImage {
                Label(text, systemImage: systemImage)
            } else {
                Text(text)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
        .lineLimit(1)
    }
}

/// One line of a benefit list: a symbol in a mint disc, a title, a line under it.
struct BenefitRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A brief message with a title, shown inline where something went wrong.
struct InlineNotice: View {
    let title: String
    let message: String
    var systemImage: String = "exclamationmark.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.smallCornerRadius, style: .continuous))
    }
}

/// A screen-wide bottom action area: the primary button and an optional quiet one,
/// on a gradient that fades the content behind it.
struct BottomActions<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 8) { content() }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                LinearGradient(colors: [Color.nivliCanvas.opacity(0), Color.nivliCanvas], startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            )
    }
}
