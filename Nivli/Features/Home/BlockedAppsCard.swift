import FamilyControls
import SwiftUI

/// What is waiting on the other side of today's workout. Nivli never learns the names —
/// `Label(token)` asks the system to draw each app's own icon and title.
struct BlockedAppsCard: View {
    @Environment(AppModel.self) private var model

    @State private var isPickerPresented = false
    @State private var selection = FamilyActivitySelection()

    /// How many rows of each kind are worth showing before the card turns into a list.
    private static let maximumAppRows = 6
    private static let maximumOtherRows = 3

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Apps that wait")
                        .font(.headline)
                    Spacer(minLength: 8)
                    if model.state.hasSelection {
                        Button("Edit") { openPicker() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                content
            }
        }
        .onAppear { selection = model.state.selection }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .onChange(of: isPickerPresented) { _, presented in
            guard !presented else { return }
            model.applySelection(selection)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.state.hasSelection {
            VStack(alignment: .leading, spacing: 12) {
                let picked = model.state.selection
                ForEach(stable(picked.applicationTokens).prefix(Self.maximumAppRows), id: \.self) { token in
                    Label(token)
                }
                ForEach(stable(picked.categoryTokens).prefix(Self.maximumOtherRows), id: \.self) { token in
                    Label(token)
                }
                ForEach(stable(picked.webDomainTokens).prefix(Self.maximumOtherRows), id: \.self) { token in
                    Label(token)
                }
                if hiddenCount > 0 {
                    Text("+\(hiddenCount) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .labelStyle(.titleAndIcon)
            .font(.body)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nothing is waiting yet. Pick the apps you want to earn.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Choose apps") { openPicker() }
                    .buttonStyle(.quiet)
            }
        }
    }

    // MARK: - Selection

    /// Tokens are opaque and unordered, so they are ordered by hash: meaningless to a
    /// person but stable between redraws, which stops the rows shuffling.
    private func stable<Item: Hashable>(_ tokens: Set<Item>) -> [Item] {
        tokens.sorted { $0.hashValue < $1.hashValue }
    }

    private var hiddenCount: Int {
        let summary = model.state.selectionSummary
        return max(0, summary.apps - Self.maximumAppRows)
            + max(0, summary.categories - Self.maximumOtherRows)
            + max(0, summary.sites - Self.maximumOtherRows)
    }

    private func openPicker() {
        selection = model.state.selection
        isPickerPresented = true
    }
}
