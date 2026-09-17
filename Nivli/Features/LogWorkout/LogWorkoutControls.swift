import SwiftUI

/// One square in the kind grid: the symbol big, the word small, and the accent when chosen —
/// a faint fill, an accent edge, and a small pool of accent light underneath.
struct KindTile: View {
    let kind: WorkoutKind
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: kind.symbolName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(kind.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.nivliSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.nivliLine, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(
                color: Color.accentColor.opacity(isSelected ? Theme.glowOpacity(0.18, in: colorScheme) : 0),
                radius: 10,
                y: 2
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A duration preset. Reads like `Chip`, behaves like a segmented choice.
struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isSelected ? Color.nivliCanvas : Color.accentColor)
                .frame(minWidth: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
                )
                .overlay(Capsule().strokeBorder(Color.accentColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
