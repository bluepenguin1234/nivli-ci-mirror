import Foundation
import SwiftUI

/// The second hero: how many days in a row, how good it has ever been, and the last seven
/// days as dots so a gap is visible before it becomes a habit. The count is the only lit
/// thing on the card, and only while there is a streak to light.
struct StreakCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    /// The streak is the biggest number on Home, so it follows the text size the person
    /// chose instead of staying at 56 points while everything around it grows.
    @ScaledMetric(relativeTo: .largeTitle) private var streakSize: CGFloat = 56

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(model.streak > 0 ? Color.accentColor : Color.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(model.streak)")
                            .font(.system(size: streakSize, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: model.streak)
                            .shadow(color: streakGlow, radius: 16)
                        TelemetryLabel("Day streak")
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        TelemetryLabel("Longest")
                        Text("\(model.longestStreak)")
                            .font(Theme.numeral(.title3))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: model.longestStreak)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Streak")
                .accessibilityValue("\(model.streak) days. Longest \(model.longestStreak).")

                WeekStrip(dots: dots)
            }
        }
    }

    /// Nothing to celebrate, nothing to light: a zero sits flat on the card.
    private var streakGlow: Color {
        guard model.streak > 0 else { return .clear }
        return Color.accentColor.opacity(Theme.glowOpacity(0.3, in: colorScheme))
    }

    /// The last seven days, oldest first, paired with the weekday initial iOS uses in this
    /// person's own locale.
    private var dots: [WeekStrip.Dot] {
        let statuses = model.weekStrip
        guard statuses.count == 7 else { return [] }
        let initials = Calendar.current.veryShortWeekdaySymbols

        var days: [DayKey] = [model.today]
        var cursor = model.today
        for _ in 0..<6 {
            cursor = cursor.previous()
            days.append(cursor)
        }
        days.reverse()

        return days.enumerated().map { index, day in
            let weekday = day.weekday()
            let initial = initials.indices.contains(weekday - 1) ? initials[weekday - 1] : ""
            return WeekStrip.Dot(id: index, initial: initial, status: statuses[index])
        }
    }
}

/// Seven dots and seven letters. Oldest on the left, today on the right. Every dot carries a
/// hairline so the row reads as a set of instruments rather than a row of blobs.
struct WeekStrip: View {
    struct Dot: Identifiable, Equatable {
        let id: Int
        let initial: String
        let status: StreakEngine.DayStatus
    }

    let dots: [Dot]

    @Environment(\.colorScheme) private var colorScheme

    private static let size: CGFloat = 26

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dots) { dot in
                VStack(spacing: 8) {
                    mark(for: dot.status)
                        .frame(width: Self.size, height: Self.size)
                    Text(dot.initial)
                        .font(Theme.telemetry)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last seven days")
        .accessibilityValue(summary)
    }

    @ViewBuilder
    private func mark(for status: StreakEngine.DayStatus) -> some View {
        switch status {
        case .done:
            ZStack {
                Circle().fill(Color.accentColor)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Color.nivliCanvas)
            }
            .overlay(Circle().strokeBorder(Theme.glassStroke, lineWidth: 1))
            .shadow(color: Color.accentColor.opacity(Theme.glowOpacity(0.35, in: colorScheme)), radius: 6)
        case .rest:
            ZStack {
                Circle().strokeBorder(Color.nivliLine, lineWidth: 1.5)
                Image(systemName: "leaf")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        case .missed:
            Circle()
                .fill(Color.nivliLine)
                .overlay(Circle().strokeBorder(Theme.glassStroke, lineWidth: 1))
        case .today:
            Circle().strokeBorder(Color.accentColor, lineWidth: 2.5)
        case .future:
            Circle().strokeBorder(Color.nivliLine, lineWidth: 1)
        }
    }

    private var summary: String {
        let done = dots.filter { $0.status == .done }.count
        return "\(done) of 7 days done"
    }
}
