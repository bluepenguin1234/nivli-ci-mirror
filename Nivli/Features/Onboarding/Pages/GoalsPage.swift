import SwiftUI

/// Page 2. What brought them here. Multi-select, at least one, and the answers only ever
/// choose copy later — nothing on this page changes what Nivli does.
struct GoalsPage: View {
    @Binding var draft: OnboardingDraft

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "What are you here for?",
                subtitle: "Pick as many as you like."
            )

            VStack(spacing: 10) {
                ForEach(Goal.allCases) { goal in
                    ChoiceRow(
                        title: goal.title,
                        systemImage: goal.symbolName,
                        isSelected: draft.goals.contains(goal)
                    ) {
                        toggle(goal)
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Add or remove without mutating the array in place, so the binding sees one new value.
    private func toggle(_ goal: Goal) {
        let next = draft.goals.contains(goal)
            ? draft.goals.filter { $0 != goal }
            : draft.goals + [goal]
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
            draft.goals = next
        }
    }
}
