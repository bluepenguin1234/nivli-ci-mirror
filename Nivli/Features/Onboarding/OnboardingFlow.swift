import SwiftUI

/// The eight onboarding pages and the paywall that closes them.
///
/// The flow owns the step, the draft and the one primary button; the pages own nothing but
/// their own layout. Every Continue writes the draft into the shared state before moving, so
/// an app killed on page 6 comes back on page 6's answers rather than an empty form.
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Int = 0
    @State private var draft = OnboardingDraft()

    var body: some View {
        Group {
            if step >= OnboardingModel.pageCount {
                PaywallView(mode: .onboarding)
            } else {
                pages
            }
        }
        .background(NivliCanvas().ignoresSafeArea())
        .onAppear { loadDraft() }
    }

    // MARK: - Layout

    private var pages: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                page
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(step)
                    .transition(pageTransition)
            }
            .scrollBounceBehavior(.basedOnSize)
            BottomActions {
                Button(OnboardingModel.primaryTitle(step: step)) { primaryAction() }
                    .buttonStyle(.prominent)
                    .disabled(!canContinue)
                    .accessibilityIdentifier("onboardingPrimaryButton")
                if let secondary = OnboardingModel.secondaryTitle(step: step) {
                    Button(secondary) { secondaryAction() }
                        .buttonStyle(.plainLink)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { goBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)
            .accessibilityHidden(step == 0)
            .accessibilityLabel("Back")

            StepProgressBar(step: step + 1, total: OnboardingModel.pageCount)
                .opacity(step > 0 ? 1 : 0)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case 0: WelcomePage()
        case 1: GoalsPage(draft: $draft)
        case 2: FrequencyPage(draft: $draft)
        case 3: PhoneHoursPage(draft: $draft)
        case 4: AppsPage()
        case 5: HealthPage(draft: $draft)
        case 6: RemindersPage(draft: $draft)
        default: SummaryPage()
        }
    }

    // MARK: - Motion

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var stepAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.32)
    }

    // MARK: - Gating

    /// The apps page is satisfied by a selection, or by Screen Time being out of reach —
    /// a simulator or a refused prompt must never be a dead end.
    private var isSelectionOK: Bool {
        switch model.screenTime.status {
        case .denied, .unavailable:
            return true
        case .notDetermined, .approved:
            return model.state.hasSelection
        }
    }

    private var canContinue: Bool {
        OnboardingModel.canContinue(step: step, draft: draft, selectionOK: isSelectionOK)
    }

    // MARK: - Actions

    private func primaryAction() {
        Haptics.light()
        persist()
        guard step == 6 else {
            moveForward()
            return
        }
        Task {
            _ = await model.setReminder(enabled: true, minutesFromMidnight: draft.reminderMinutes)
            draft.reminderEnabled = model.state.reminderEnabled
            moveForward()
        }
    }

    private func secondaryAction() {
        Haptics.light()
        persist()
        Task {
            _ = await model.setReminder(enabled: false, minutesFromMidnight: draft.reminderMinutes)
            draft.reminderEnabled = false
            moveForward()
        }
    }

    private func moveForward() {
        withAnimation(stepAnimation) {
            step = min(step + 1, OnboardingModel.pageCount)
        }
    }

    private func goBack() {
        withAnimation(stepAnimation) {
            step = max(step - 1, 0)
        }
    }

    // MARK: - Persistence

    /// Copies the answers so far into the shared state. Called at every Continue rather than
    /// at every tap, so the store is written once per page.
    private func persist() {
        let answers = draft
        model.update {
            $0.goals = answers.goals
            $0.currentFrequency = answers.frequency
            $0.dailyPhoneHours = answers.phoneHours
            $0.minimumMinutes = answers.minimumMinutes
        }
    }

    /// Picks up where a killed app left off: the draft starts from whatever was saved.
    private func loadDraft() {
        let state = model.state
        var restored = OnboardingDraft()
        restored.goals = state.goals
        restored.frequency = state.currentFrequency
        restored.phoneHours = state.dailyPhoneHours
        restored.minimumMinutes = state.minimumMinutes
        restored.reminderEnabled = state.reminderEnabled
        restored.reminderMinutes = state.reminderMinutesFromMidnight
        restored.healthConnected = state.healthEnabled
        draft = restored
    }
}
