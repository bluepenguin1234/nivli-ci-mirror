import SwiftUI

/// The app itself: one window, one model, one appearance.
@main
struct NivliApp: App {
    /// The launch argument the UI test passes to get a fresh install every run.
    private static let resetArgument = "-nivli-reset"

    @State private var model: AppModel
    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.dark.rawValue
    @Environment(\.scenePhase) private var scenePhase

    /// Order matters here. `-nivli-reset` has to empty the App Group *before* `AppModel` is
    /// built, because the model reads the stored state in its own initialiser — so the model
    /// is created explicitly in the body of this initialiser rather than as a property
    /// default, which Swift would have run first.
    init() {
        #if DEBUG
        // Debug builds only: a release build must never be able to wipe somebody's data
        // from a launch argument.
        if CommandLine.arguments.contains(Self.resetArgument) {
            SharedStore.shared.reset()
        }
        #endif
        NivliPalette.styleSystemControls()
        let model = AppModel.live()
        // Health background delivery needs the observer registered at launch, not at the
        // first screen: iOS may have started Nivli in the background for a new workout.
        model.prepareForLaunch()
        _model = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
                .task { await model.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await model.refresh() }
                    }
                }
        }
    }
}
