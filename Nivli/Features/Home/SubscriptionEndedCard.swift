import SwiftUI

/// Shown on Home when the subscription lapsed. Nothing is locked while it is up — Nivli
/// fails open — so the card says so plainly rather than pretending the streak is at risk.
struct SubscriptionEndedCard: View {
    @Environment(AppModel.self) private var model

    /// Opens the paywall. Home owns the presentation so the cover sits over the whole screen.
    let onStartAgain: () -> Void

    @State private var isRestoring = false

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your subscription ended")
                    .font(.headline)
                Text("Nothing is locked. Start again to keep your streak going.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Start again") { onStartAgain() }
                    .buttonStyle(.prominent)
                Button("Restore Purchases") { restore() }
                    .buttonStyle(.plainLink)
                    .disabled(isRestoring)
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            _ = await model.subscriptions.restore()
            isRestoring = false
        }
    }
}
