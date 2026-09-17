import Foundation
import Observation
import StoreKit
import os

/// Everything StoreKit, in one place: the products the paywall shows, whether this person is
/// entitled, and the one write of `entitlementValidUntil` into the App Group.
///
/// Nothing here ever throws at a caller. A failure becomes a `UserFacingError` on
/// `loadError` or a `.failed` outcome, and the app keeps running with no entitlement — which
/// is Nivli's fail-open position: no subscription means no shields, ever.
@MainActor
@Observable
final class SubscriptionStore {
    /// What came back from a purchase attempt, in the four shapes the paywall reacts to.
    enum PurchaseOutcome: Equatable {
        case success
        case cancelled
        case pending
        case failed(UserFacingError)
    }

    /// The plans on sale, in `AppConfig.productIDs` order.
    private(set) var products: [Product] = []
    private(set) var isSubscribed: Bool = false
    /// When access runs out. `.distantFuture` for the lifetime purchase, `nil` for nobody.
    private(set) var validUntil: Date?
    private(set) var isLoadingProducts: Bool = false
    private(set) var isPurchasing: Bool = false
    /// Set when the App Store could not be reached; the paywall shows it with a retry.
    private(set) var loadError: UserFacingError?

    /// `AppModel` sets this so the rest of the app learns about a renewal, a refund or a
    /// restore the moment StoreKit does.
    var onEntitlementChange: ((Date?) -> Void)?

    private let sharedStore: SharedStore
    private let logger = Logger(subsystem: "com.bluepenguin.nivli", category: "store-kit")
    /// The long-lived listener for renewals and refunds that arrive while the app is open.
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(sharedStore: SharedStore = .shared) {
        self.sharedStore = sharedStore
    }

    /// The one plan Nivli sells today.
    var monthlyProduct: Product? {
        products.first { $0.id == AppConfig.monthlyProductID }
    }

    // MARK: - Lifecycle

    /// Loads the products, reads the current entitlements and starts listening. Safe to call
    /// more than once: the listener is replaced rather than duplicated.
    func start() async {
        await loadProducts()
        await refreshEntitlements()
        listenForTransactions()
    }

    /// Asks the App Store for the plans on sale. Keeps `AppConfig.productIDs` order so the
    /// paywall never reshuffles itself between launches.
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: AppConfig.productIDs)
            let order = AppConfig.productIDs
            products = loaded.sorted { first, second in
                (order.firstIndex(of: first.id) ?? order.count) < (order.firstIndex(of: second.id) ?? order.count)
            }
            loadError = nil
        } catch {
            logger.error("Products could not be loaded: \(error.localizedDescription, privacy: .public)")
            loadError = UserFacingError(
                title: "The App Store didn't answer",
                message: "Nivli couldn't load the price just now. Check your connection and try again."
            )
        }
    }

    /// Reads every verified entitlement, works out when access runs out, and writes that one
    /// date into the shared store so the extensions see the same answer.
    ///
    /// `onEntitlementChange` is called on every pass, not only on a change: the callback is
    /// cheap, `AppModel` ignores a value it already has, and calling it unconditionally is
    /// what clears a stale date left behind by an older install.
    func refreshEntitlements() async {
        var snapshots: [EntitlementSnapshot] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard AppConfig.entitlementProductIDs.contains(transaction.productID) else { continue }
            snapshots.append(
                EntitlementSnapshot(
                    productID: transaction.productID,
                    isSubscription: transaction.productType == .autoRenewable,
                    expirationDate: transaction.expirationDate,
                    revocationDate: transaction.revocationDate
                )
            )
        }

        let until = SubscriptionStore.validUntil(entitlements: snapshots)
        validUntil = until
        isSubscribed = until.map { $0 > Date() } ?? false
        sharedStore.update { $0.entitlementValidUntil = until }
        onEntitlementChange?(until)
        logger.log("Entitlements refreshed: \(snapshots.count) verified, subscribed=\(self.isSubscribed)")
    }

    // MARK: - Buying

    /// Buys a plan. The outcome is always one of the four cases; nothing throws out of here.
    func purchase(_ product: Product) async -> PurchaseOutcome {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    return .success
                case .unverified:
                    logger.error("A purchase came back unverified")
                    return .failed(
                        UserFacingError(
                            title: "That purchase couldn't be verified",
                            message: "The App Store couldn't confirm the receipt. Try Restore Purchases, or try again in a moment."
                        )
                    )
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(
                    UserFacingError(
                        title: "That didn't go through",
                        message: "The App Store returned something Nivli didn't understand. Try again in a moment."
                    )
                )
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            return .failed(
                UserFacingError(title: "That didn't go through", message: error.localizedDescription)
            )
        }
    }

    /// Restores a purchase made on another device or before a reinstall.
    @discardableResult
    func restore() async -> Bool {
        try? await AppStore.sync()
        await refreshEntitlements()
        return isSubscribed
    }

    // MARK: - Copy

    /// "$2.99 / month" for a subscription, "$39.99 once" for the lifetime purchase. The
    /// price and the period always come from the storefront, never from Nivli.
    func priceLine(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return "\(product.displayPrice) once"
        }
        return "\(product.displayPrice) / \(SubscriptionStore.phrase(for: period))"
    }

    /// The introductory offer, said plainly — or `nil` when there is none.
    func introductoryOfferLine(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer else { return nil }
        let then = priceLine(for: product)
        switch offer.paymentMode {
        case .freeTrial:
            let days = SubscriptionStore.approximateDays(in: offer.period)
            return "\(days) days free, then \(then)"
        case .payAsYouGo, .payUpFront:
            return "\(offer.displayPrice) for the first \(SubscriptionStore.phrase(for: offer.period)), then \(then)"
        default:
            return nil
        }
    }

    // MARK: - Private

    /// Renewals, refunds and purchases made elsewhere land here while the app is open.
    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task.detached { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    /// "month", "3 months", "week" — the noun that follows a price.
    private static func phrase(for period: Product.SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        default: unit = "period"
        }
        return period.value == 1 ? unit : "\(period.value) \(unit)s"
    }

    /// A free trial reads best in days, so a week or a month is converted to the number
    /// people expect to see ("7 days free", "30 days free").
    private static func approximateDays(in period: Product.SubscriptionPeriod) -> Int {
        let perUnit: Int
        switch period.unit {
        case .day: perUnit = 1
        case .week: perUnit = 7
        case .month: perUnit = 30
        case .year: perUnit = 365
        default: perUnit = 1
        }
        return period.value * perUnit
    }
}
