import Foundation
import StoreKit
import SwiftUI

/// Everything Nivli can be told, in one list. Every write goes through `model.update`, so
/// the shields and the shared state can never drift from what the screen shows.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.dark.rawValue

    @State private var isManagingSubscription = false
    @State private var isShowingPaywall = false
    @State private var isConfirmingReset = false
    @State private var isRestoring = false

    var body: some View {
        List {
            AppsThatWaitSection()
            AppleHealthSection()
            whatCountsSection
            RestDaysSection()
            RemindersSection()
            appearanceSection
            subscriptionSection
            aboutSection
            resetSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .nivliScreen()
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .fullScreenCover(isPresented: $isShowingPaywall) {
            PaywallView(mode: .resubscribe)
        }
    }

    // MARK: - What counts

    private var whatCountsSection: some View {
        Section {
            Picker("Minimum workout", selection: minimumMinutes) {
                ForEach(SharedConstants.minimumMinuteChoices, id: \.self) { choice in
                    Text("\(choice) min").tag(choice)
                }
            }
            .pickerStyle(.menu)
            .nivliRow()
        } header: {
            Text("What counts")
        } footer: {
            Text("A shorter workout is saved, but it does not unlock your apps.")
        }
    }

    private var minimumMinutes: Binding<Int> {
        Binding(
            get: { model.state.minimumMinutes },
            set: { value in model.update { $0.minimumMinutes = value } }
        )
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearance) {
                ForEach(AppearanceSetting.allCases) { setting in
                    Text(setting.title).tag(setting.rawValue)
                }
            }
            .pickerStyle(.menu)
            .nivliRow()
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section {
            HStack {
                Text("Status")
                Spacer(minLength: 8)
                Text(subscriptionStatus)
                    .foregroundStyle(.secondary)
            }
            .nivliRow()

            Button("Manage subscription") { isManagingSubscription = true }
                .nivliRow()

            Button("Restore Purchases") { restore() }
                .disabled(isRestoring)
                .nivliRow()

            if !model.isSubscribed {
                Button("Start again") { isShowingPaywall = true }
                    .nivliRow()
            }
        } header: {
            Text("Subscription")
        }
    }

    /// "renews" is a promise, so it is only made when StoreKit says auto-renewal is on. A
    /// cancelled subscription still has days left, and is told exactly that.
    private var subscriptionStatus: String {
        guard model.isSubscribed else { return "Not active" }
        guard let validUntil = model.subscriptions.validUntil else { return "Active" }
        if validUntil == .distantFuture { return "Lifetime" }
        let date = validUntil.formatted(date: .abbreviated, time: .omitted)
        return model.subscriptions.willAutoRenew ? "Active · renews \(date)" : "Active until \(date)"
    }

    private func restore() {
        isRestoring = true
        Task {
            _ = await model.subscriptions.restore()
            isRestoring = false
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Link("Support", destination: AppConfig.supportURL)
                .nivliRow()
            Link("Privacy Policy", destination: AppConfig.privacyURL)
                .nivliRow()
            Link("Terms of Use", destination: AppConfig.termsURL)
                .nivliRow()
            HStack {
                Text("Version")
                Spacer(minLength: 8)
                Text(AppConfig.versionString)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .nivliRow()
        } header: {
            Text("About")
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button("Turn off Nivli and delete my data", role: .destructive) {
                isConfirmingReset = true
            }
            .nivliRow()
            .confirmationDialog(
                "Turn off Nivli and delete my data?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) { model.resetEverything() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every lock, forgets your streak and takes you back to the first screen.")
            }
        } header: {
            Text("Reset")
        } footer: {
            Text("Nivli keeps everything on this iPhone. There is no account and nothing is sent anywhere.")
        }
    }
}
