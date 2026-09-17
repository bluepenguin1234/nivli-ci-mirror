import SwiftUI

/// Page 4. The one page that pushes back a little: after the answer, the hours turn into
/// days of a year. It is the argument for the whole app, made with the person's own number.
struct PhoneHoursPage: View {
    @Binding var draft: OnboardingDraft

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "How much of your day goes to your phone?",
                subtitle: "Social apps only. A rough guess is fine."
            )

            forecastCard

            VStack(spacing: 10) {
                ForEach(PhoneHours.allCases) { hours in
                    ChoiceRow(
                        title: hours.title,
                        isSelected: draft.phoneHours == hours
                    ) {
                        select(hours)
                    }
                }
            }
            .padding(.top, 4)

            if let days = draft.phoneHours?.daysPerYear {
                yearCard(days: days)
                    .transition(reveal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The hook, above the question: the number the person is about to estimate, stated as an
    /// average rather than as a fact about them. It is the argument in one eyeful, and it is the
    /// only lit thing on the page until they answer.
    private var forecastCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 6) {
                TelemetryLabel("Today's forecast")
                Text("5–6 h")
                    .font(Theme.numeral(.largeTitle))
                    .foregroundStyle(Color.accentColor)
                    .modifier(Theme.glow(.accentColor, radius: 18))
                Text("is what the average person spends on their phone today.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Most of it in the same few apps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Today's forecast. 5 to 6 hours is what the average person spends on their phone today. Most of it in the same few apps."
        )
    }

    private func yearCard(days: Int) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("≈ \(days) days")
                    .font(Theme.numeral(.largeTitle))
                    .foregroundStyle(Color.accentColor)
                Text("of your year, on your phone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("About \(days) days of your year, on your phone.")
    }

    private var reveal: AnyTransition {
        reduceMotion
            ? .opacity
            : .opacity.combined(with: .move(edge: .bottom))
    }

    private func select(_ hours: PhoneHours) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            draft.phoneHours = hours
        }
    }
}
