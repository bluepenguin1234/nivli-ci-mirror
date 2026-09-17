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
