import SwiftUI

/// Page 3. How often they move today. One answer, and like the goals it is kept for copy
/// rather than for logic — Nivli never judges the number.
struct FrequencyPage: View {
    @Binding var draft: OnboardingDraft

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "How often do you move now?",
                subtitle: "There is no wrong answer. Nivli starts where you are."
            )

            VStack(spacing: 10) {
                ForEach(Frequency.allCases) { frequency in
                    ChoiceRow(
                        title: frequency.title,
                        isSelected: draft.frequency == frequency
                    ) {
                        select(frequency)
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func select(_ frequency: Frequency) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
            draft.frequency = frequency
        }
    }
}
