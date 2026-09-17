import StoreKit
import SwiftUI

/// The one thing Nivli sells, on one screen.
///
/// Two modes, one layout. At the end of onboarding it is the last page and has no way out
/// except buying or restoring; opened later from Home or Settings it is a sheet with a close
/// button. Price, period and any introductory offer come from StoreKit, never from a literal.
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

    private var store: SubscriptionStore { model.subscriptions }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heading
                benefits
                planSection
                legal
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .top) { closeBar }
        .background(NivliCanvas().ignoresSafeArea())
        .task {
            // Someone who already pays (a Nivli+ subscriber from 2.x, or a reinstall) never
            // sees a price: the entitlement StoreKit found at launch walks them straight through.
            if model.isSubscribed {
                finish()
                return
            }
            if store.products.isEmpty { await store.loadProducts() }
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

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            BenefitRow(
                systemImage: "lock.fill",
                title: "The apps you chose stay shut",
                detail: "Until a workout says otherwise. Nivli never sees which apps they are."
            )
            BenefitRow(
                systemImage: "heart.fill",
                title: "Apple Health unlocks them for you",
                detail: "A Watch run or a gym session opens everything without opening Nivli."
            )
            BenefitRow(
                systemImage: "flame.fill",
                title: "Streaks that make it stick",
                detail: "Rest days are yours to take. The streak survives them."
            )
        }
    }

    @ViewBuilder
    private var planSection: some View {
        if let error = store.loadError {
            InlineNotice(title: error.title, message: error.message)
            Button("Try again") {
                Task { await store.loadProducts() }
            }
            .buttonStyle(.quiet)
        } else if let product = store.monthlyProduct {
            planCard(for: product)
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
                Task { await store.loadProducts() }
            }
            .buttonStyle(.quiet)
        }
    }

    private func planCard(for product: Product) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppConfig.appName)
                    .font(.title3.weight(.bold))
                Text(store.priceLine(for: product))
                    .font(Theme.numeral(.title2))
                    .foregroundStyle(Color.accentColor)
                if let offer = store.introductoryOfferLine(for: product) {
                    Text(offer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Chip(text: "Cancel anytime", systemImage: "checkmark.circle.fill", tint: .accentColor)
                    .padding(.top, 2)
            }
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

    private var legal: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payment is charged to your Apple Account at confirmation. The subscription renews automatically each month at the same price unless cancelled at least 24 hours before the end of the period. Manage or cancel in Settings › Apple Account › Subscriptions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                Link("Terms of Use", destination: AppConfig.termsURL)
                Link("Privacy Policy", destination: AppConfig.privacyURL)
            }
            .font(.caption.weight(.semibold))
        }
    }

    // MARK: - Actions

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
