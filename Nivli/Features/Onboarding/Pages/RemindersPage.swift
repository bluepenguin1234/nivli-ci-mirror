import SwiftUI

/// Page 7. One evening nudge, at a time they choose, only if today is not done yet. The
/// quiet button under Continue is a real answer, not a way of asking twice.
struct RemindersPage: View {
    @Binding var draft: OnboardingDraft

    @State private var time = OnboardingModel.date(fromMinutesFromMidnight: 18 * 60)

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "Stay on track",
                subtitle: "One nudge in the evening, and only on the days you have not moved yet."
            )

            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        "Remind me at",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.body.weight(.semibold))

                    Divider().overlay(Color.nivliLine)

                    Text("Nothing else. Nivli does not send streak warnings or marketing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            time = OnboardingModel.date(fromMinutesFromMidnight: draft.reminderMinutes)
        }
        .onChange(of: time) { _, newValue in
            draft.reminderMinutes = OnboardingModel.minutesFromMidnight(for: newValue)
        }
    }
}
