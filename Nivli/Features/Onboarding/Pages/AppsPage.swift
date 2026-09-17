import FamilyControls
import SwiftUI

/// Page 5. The permission page. Screen Time is the only thing Nivli asks for that sounds
/// serious, so it is explained in two lines before the system is allowed to ask, and every
/// refusal has a way forward — nothing here can trap someone in onboarding.
struct AppsPage: View {
    @Environment(AppModel.self) private var model

    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stackSpacing) {
            PageHeading(
                title: "Choose the apps that wait",
                subtitle: "Screen Time lets Nivli hold those apps shut until you have moved."
            )

            Text("Nivli never sees which apps you picked. iOS keeps the list and draws the names.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SurfaceCard {
                VStack(alignment: .leading, spacing: 14) {
                    switch model.screenTime.status {
                    case .notDetermined:
                        permissionPrompt
                    case .approved:
                        picker
                    case .denied:
                        InlineNotice(
                            title: "Screen Time is off",
                            message: "Nivli cannot lock anything without it. Carry on for now, and turn it on later in Settings."
                        )
                    case .unavailable(let message):
                        InlineNotice(
                            title: "Screen Time is unavailable",
                            message: "\(message) You can carry on and set this up later in Settings."
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .onAppear { selection = model.state.selection }
        .onChange(of: isPickerPresented) { _, presented in
            guard !presented else { return }
            model.applySelection(selection)
        }
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iOS will ask once. Nivli only uses it on this iPhone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await model.screenTime.request() }
            } label: {
                if model.screenTime.isRequesting {
                    ProgressView()
                } else {
                    Text("Allow Screen Time")
                }
            }
            .buttonStyle(.quiet)
            .disabled(model.screenTime.isRequesting)
        }
    }

    private var picker: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.state.hasSelection {
                Chip(text: summaryLine, systemImage: "checkmark.circle.fill", tint: .accentColor)
            } else {
                Text("Pick the apps, categories or sites that should wait.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(model.state.hasSelection ? "Change apps" : "Choose apps") {
                isPickerPresented = true
            }
            .buttonStyle(.quiet)
        }
    }

    /// "3 apps · 1 category · 2 sites", with the parts that are zero left out.
    private var summaryLine: String {
        let summary = model.state.selectionSummary
        var parts: [String] = []
        if summary.apps > 0 { parts.append("\(summary.apps) \(summary.apps == 1 ? "app" : "apps")") }
        if summary.categories > 0 {
            parts.append("\(summary.categories) \(summary.categories == 1 ? "category" : "categories")")
        }
        if summary.sites > 0 { parts.append("\(summary.sites) \(summary.sites == 1 ? "site" : "sites")") }
        return parts.isEmpty ? "Nothing chosen yet" : parts.joined(separator: " · ")
    }
}
