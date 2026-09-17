import SwiftUI

/// The only routing decision the app makes: onboarding until it is finished, Home after.
///
/// The canvas is painted once, here, and both destinations sit on it — so the cross-fade
/// between them happens over an unchanging background rather than flashing black.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            NivliCanvas().ignoresSafeArea()

            if model.state.onboardingComplete {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: model.state.onboardingComplete)
    }
}
