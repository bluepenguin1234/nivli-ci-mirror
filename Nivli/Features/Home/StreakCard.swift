import Foundation
import SwiftUI

/// The second hero: how many days in a row, how good it has ever been, and the last seven
/// days as dots so a gap is visible before it becomes a habit.
struct StreakCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(model.streak > 0 ? Color.accentColor : Color.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: -2) {
                        Text("\(model.streak)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: model.streak)
                        Text("day streak")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Longest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

/// Seven dots and seven letters. Oldest on the left, today on the right.
struct WeekStrip: View {
    struct Dot: Identifiable, Equatable {
        let id: Int
        let initial: String
        let status: StreakEngine.DayStatus
    }

    let dots: [Dot]

    private static let size: CGFloat = 26

    var body: some View {
        HStack(spacing: 0) {
            ForEach(dots) { dot in
                VStack(spacing: 8) {
                    mark(for: dot.status)
                        .frame(width: Self.size, height: Self.size)
                    Text(dot.initial)
                        .font(.caption2.weight(.medium))
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
        case .rest:
            ZStack {
                Circle().strokeBorder(Color.nivliLine, lineWidth: 1.5)
                Image(systemName: "leaf")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        case .missed:
            Circle().fill(Color.nivliLine)
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
