import SwiftUI

/// Page 8. Everything they just chose, read back in one card, then the week ahead with
/// today lit. The last thing before the paywall is a promise, not an ask.
struct SummaryPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "Your first streak starts today",
                subtitle: "Here is how Nivli is set up. All of it can change later in Settings."
            )

            SurfaceCard {
                VStack(alignment: .leading, spacing: 0) {
                    row(label: "Apps that wait", value: appsValue, isFirst: true)
                    row(label: "Counts as a workout", value: "≥ \(model.state.minimumMinutes) min")
                    row(label: "Apple Health", value: model.state.healthEnabled ? "On" : "Off")
                    row(label: "Reminder", value: reminderValue)
                }
            }

            weekPreview

            Text("Your first streak starts with today's workout.")
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(label: String, value: String, isFirst: Bool = false) -> some View {
        VStack(spacing: 0) {
            if !isFirst {
                Divider().overlay(Color.nivliLine).padding(.vertical, 12)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Six quiet dots for the days to come and one accent dot with a ring for today.
    private var weekPreview: some View {
        HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { index in
                if index == 6 {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 3)
                                .frame(width: 26, height: 26)
                        )
                } else {
                    Circle()
                        .fill(Color.nivliLine)
                        .frame(width: 14, height: 14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A week of days, with today highlighted.")
    }

    private var appsValue: String {
        let summary = model.state.selectionSummary
        guard model.state.hasSelection else { return "Not chosen yet" }
        var parts: [String] = []
        if summary.apps > 0 { parts.append("\(summary.apps) \(summary.apps == 1 ? "app" : "apps")") }
        if summary.categories > 0 {
            parts.append("\(summary.categories) \(summary.categories == 1 ? "category" : "categories")")
        }
        if summary.sites > 0 { parts.append("\(summary.sites) \(summary.sites == 1 ? "site" : "sites")") }
        return parts.isEmpty ? "Not chosen yet" : parts.joined(separator: " · ")
    }

    private var reminderValue: String {
        guard model.state.reminderEnabled else { return "Off" }
        let date = OnboardingModel.date(fromMinutesFromMidnight: model.state.reminderMinutesFromMidnight)
        return date.formatted(date: .omitted, time: .shortened)
    }
}
