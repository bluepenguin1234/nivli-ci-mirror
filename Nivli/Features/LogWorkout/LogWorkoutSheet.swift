import SwiftUI

/// Two taps and a number. The sheet is deliberately honest about the honor system, and
/// about what a short workout does and does not do.
struct LogWorkoutSheet: View {
    /// Handed the result so Home can celebrate; the sheet has already dismissed itself.
    let onLogged: (LogResult) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var kind: WorkoutKind = .run
    @State private var minutes: Int = SharedConstants.defaultMinimumMinutes
    @State private var didSeedMinutes = false

    private static let presets = [10, 15, 20, 30, 45, 60, 90]
    private static let columns = [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heading
                    kindGrid
                    duration
                    statusLine
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom) {
                BottomActions {
                    Button("Log it") { log() }
                        .buttonStyle(.prominent)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .nivliSheet()
        .onAppear(perform: seedMinutes)
    }

    // MARK: - Pieces

    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            PageHeading(title: "Log a workout")
            Text("Honor system. Nivli only works if you're straight with yourself.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var kindGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 12) {
            ForEach(WorkoutKind.allCases) { option in
                KindTile(kind: option, isSelected: option == kind) {
                    Haptics.light()
                    kind = option
                }
            }
        }
    }

    private var duration: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How long")
                .font(.headline)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Self.presets, id: \.self) { preset in
                        DurationChip(minutes: preset, isSelected: preset == minutes) {
                            Haptics.light()
                            minutes = preset
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            Stepper(value: $minutes, in: 5...240, step: 5) {
                Text("\(minutes) min")
                    .font(Theme.numeral(.title3))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: minutes)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.nivliSurface, in: RoundedRectangle(cornerRadius: Theme.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius, style: .continuous)
                    .strokeBorder(Color.nivliLine)
            )
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if minutes >= model.state.minimumMinutes {
            Label("Counts toward today", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        } else {
            Text("Under your \(model.state.minimumMinutes)-minute minimum. It's saved, but your apps stay locked.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    /// The default duration is whatever counts today, so the common case is one tap.
    private func seedMinutes() {
        guard !didSeedMinutes else { return }
        didSeedMinutes = true
        minutes = model.state.minimumMinutes
    }

    private func log() {
        Haptics.success()
        let result = model.logWorkout(kind: kind, minutes: minutes)
        dismiss()
        onLogged(result)
    }
}
