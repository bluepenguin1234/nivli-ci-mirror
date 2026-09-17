import SwiftUI

/// The one screen Nivli lives on: the ring, the streak, the button that unlocks the day.
///
/// Everything here reads from `AppModel` and writes through exactly one of its methods, so
/// the shields, the streak and the pixels can never disagree.
struct HomeView: View {
    @Environment(AppModel.self) private var model

    @State private var isLoggingWorkout = false
    @State private var isShowingPaywall = false
    /// Set when a log unlocked the day; drives the celebration overlay.
    @State private var celebration: LogResult?

    /// How long the celebration stays before it lets go of the screen.
    private static let celebrationSeconds: Double = 2.2

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackSpacing) {
                    StatusHero()
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    StreakCard()
                    primaryAction
                    if showsSubscriptionEnded {
                        SubscriptionEndedCard { isShowingPaywall = true }
                    }
                    BlockedAppsCard()
                    if let error = model.monitoringError {
                        InlineNotice(title: error.title, message: error.message)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 44)
            }
            .refreshable { await model.refresh() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NivliMark(height: 22)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .nivliScreen()
            .sheet(isPresented: $isLoggingWorkout) {
                LogWorkoutSheet { result in
                    handle(result)
                }
            }
            .fullScreenCover(isPresented: $isShowingPaywall) {
                PaywallView(mode: .resubscribe)
            }
        }
        .overlay {
            if let celebration {
                CelebrationView(result: celebration) { dismissCelebration() }
                    .transition(.opacity)
            }
        }
        .task(id: celebration) {
            guard celebration != nil else { return }
            try? await Task.sleep(for: .seconds(Self.celebrationSeconds))
            guard !Task.isCancelled else { return }
            dismissCelebration()
        }
    }

    // MARK: - Pieces

    /// Locked: the loud invitation. Unlocked: a quiet way to add a second workout.
    @ViewBuilder
    private var primaryAction: some View {
        if model.decision.isLocked {
            Button("Log a workout") { startLogging() }
                .buttonStyle(.prominent)
        } else {
            Button("Add another") { startLogging() }
                .buttonStyle(.quiet)
        }
    }

    /// The lapsed-subscription card only makes sense to someone who already finished
    /// onboarding; before that the paywall is the next step anyway.
    private var showsSubscriptionEnded: Bool {
        !model.isSubscribed && model.state.onboardingComplete
    }

    // MARK: - Actions

    private func startLogging() {
        Haptics.light()
        isLoggingWorkout = true
    }

    private func handle(_ result: LogResult) {
        guard result.unlocked else { return }
        withAnimation(.easeOut(duration: 0.2)) { celebration = result }
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.25)) { celebration = nil }
    }
}
