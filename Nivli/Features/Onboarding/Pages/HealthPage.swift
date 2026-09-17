import SwiftUI

/// Page 6. How Nivli finds out that they moved: Apple Health if they want it, two taps if
/// they do not, and the minimum that decides what counts either way.
struct HealthPage: View {
    @Binding var draft: OnboardingDraft

    @Environment(AppModel.self) private var model
    @State private var isConnecting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "How will Nivli know you moved?",
                subtitle: "Apple Health can unlock your apps on its own, even while Nivli is closed."
            )

            if model.health.isAvailable {
                healthCard
            }

            Text("Or log it yourself in two taps.")
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            minimumPicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var healthCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.14), in: Circle())
                        .accessibilityHidden(true)
                    Text("Apple Health")
                        .font(.body.weight(.semibold))
                    Spacer(minLength: 8)
                    if model.state.healthEnabled {
                        Chip(text: "Connected", systemImage: "checkmark.circle.fill", tint: .accentColor)
                    }
                }

                Text("Nivli reads your workouts and nothing else. A Watch run unlocks your apps before you are back indoors.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !model.state.healthEnabled {
                    Button {
                        connect()
                    } label: {
                        if isConnecting {
                            ProgressView()
                        } else {
                            Text("Connect Apple Health")
                        }
                    }
                    .buttonStyle(.quiet)
                    .disabled(isConnecting)
                }
            }
        }
    }

    private var minimumPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Minimum minutes for a workout to count", selection: $draft.minimumMinutes) {
                ForEach(SharedConstants.minimumMinuteChoices, id: \.self) { minutes in
                    Text("\(minutes)").tag(minutes)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("Minimum minutes for a workout to count")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private func connect() {
        isConnecting = true
        Task {
            let granted = await model.connectHealth()
            draft.healthConnected = granted
            isConnecting = false
            if granted { Haptics.light() }
        }
    }
}
