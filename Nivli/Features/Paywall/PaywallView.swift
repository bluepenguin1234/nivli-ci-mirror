import StoreKit
import SwiftUI

/// The one thing Nivli sells, on one screen.
///
/// Two modes, one layout. At the end of onboarding it is the last page and has no way out
/// except buying or restoring; opened later from Home or Settings it is a sheet with a close
/// button. Price, period and any introductory offer come from StoreKit, never from a literal.
///
/// Nobody is ever trapped here. If the App Store cannot be reached twice in a row, the
/// onboarding paywall offers a way through without paying — nothing is locked until there is
/// a subscription, so letting somebody past costs nothing and being stuck costs everything.
struct PaywallView: View {
    enum Mode: Equatable {
        /// The final onboarding step. Success finishes onboarding; there is no close button.
        case onboarding
        /// Reopened after the subscription lapsed. Success or close dismisses the sheet.
        case resubscribe
    }

    let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseError: UserFacingError?
    @State private var notice: String?
    @State private var isRestoring = false
    /// How many times loading the products has come back empty-handed on this screen.
    @State private var failedLoads = 0

    private var store: SubscriptionStore { model.subscriptions }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heading
                PaywallBenefits()
                planSection
                PaywallLegal()
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .top) { closeBar }
        .background(NivliGlow().ignoresSafeArea())
        .task {
            // Someone who already pays (a Nivli+ subscriber from 2.x, or a reinstall) never
            // sees a price: the entitlement StoreKit found at launch walks them straight through.
            if model.isSubscribed {
                finish()
                return
            }
            if store.products.isEmpty { await reload() }
        }
        .onChange(of: model.isSubscribed) { _, subscribed in
            if subscribed { finish() }
        }
    }

    // MARK: - Pieces

    @ViewBuilder
    private var closeBar: some View {
        if mode == .resubscribe {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 18) {
            NivliMark(height: 44)
                .padding(.top, mode == .resubscribe ? 0 : 24)
            Text("Unlock your apps by moving first")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private var planSection: some View {
        if let error = store.loadError {
            InlineNotice(title: error.title, message: error.message)
            Button("Try again") {
                Task { await reload() }
            }
            .buttonStyle(.quiet)
            escapeHatch
        } else if let product = store.monthlyProduct {
            PaywallPlanCard(
                priceLine: store.priceLine(for: product),
                introductoryOfferLine: store.introductoryOfferLine(for: product)
            )
            purchaseControls(for: product)
        } else if store.isLoadingProducts {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 32)
            purchaseControls(for: nil)
        } else {
            InlineNotice(
                title: "The App Store did not answer",
                message: "Check your connection and try again."
            )
            Button("Try again") {
                Task { await reload() }
            }
            .buttonStyle(.quiet)
            escapeHatch
        }
    }

    /// The way out of a paywall that cannot load. Only in onboarding, where there is no close
    /// button; the resubscribe sheet already has one.
    @ViewBuilder
    private var escapeHatch: some View {
        if failedLoads >= 2 && mode == .onboarding {
            Button("Continue without subscribing") { model.completeOnboarding() }
                .buttonStyle(.plainLink)
            Text("Nothing will be locked until you subscribe.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The buy and restore buttons. `product` is `nil` only while the App Store is still
    /// answering, when the button reads "Subscribe" and does nothing.
    @ViewBuilder
    private func purchaseControls(for product: Product?) -> some View {
        VStack(spacing: 8) {
            Button {
                guard let product else { return }
                buy(product)
            } label: {
                if store.isPurchasing {
                    ProgressView()
                } else if let product {
                    Text("Start for \(store.priceLine(for: product))")
                } else {
                    Text("Subscribe")
                }
            }
            .buttonStyle(.prominent)
            .disabled(product == nil || store.isPurchasing || isRestoring)
            .accessibilityIdentifier("paywallSubscribeButton")

            Button("Restore Purchases") { restore() }
                .buttonStyle(.plainLink)
                .disabled(store.isPurchasing || isRestoring)
        }

        if let purchaseError {
            InlineNotice(title: purchaseError.title, message: purchaseError.message)
        }
        if let notice {
            Text(notice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    /// One load of the products, counting the failures so the escape hatch can appear.
    private func reload() async {
        await store.loadProducts()
        if store.loadError != nil { failedLoads += 1 }
    }

    private func buy(_ product: Product) {
        purchaseError = nil
        notice = nil
        Task {
            let outcome = await store.purchase(product)
            switch outcome {
            case .success:
                finish()
            case .cancelled:
                notice = "No charge was made."
            case .pending:
                notice = "Your purchase is waiting for approval. Nivli unlocks as soon as it goes through."
            case .failed(let error):
                purchaseError = error
            }
        }
    }

    private func restore() {
        purchaseError = nil
        notice = nil
        isRestoring = true
        Task {
            let restored = await store.restore()
            isRestoring = false
            if restored {
                finish()
            } else {
                notice = "Nothing to restore on this Apple Account."
            }
        }
    }

    /// The subscription is live: finish onboarding, or step out of the way.
    private func finish() {
        Haptics.success()
        switch mode {
        case .onboarding:
            model.completeOnboarding()
        case .resubscribe:
            dismiss()
        }
    }
}
