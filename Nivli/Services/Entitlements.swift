import Foundation

/// A framework-free view of one verified StoreKit transaction.
///
/// `SubscriptionStore` turns every `Transaction` it trusts into one of these before deciding
/// anything, so the rule that says "when does this person's access run out" is a pure
/// function of plain values and can be unit-tested off-device, where no `Transaction` can
/// ever be minted.
struct EntitlementSnapshot: Equatable {
    /// The product this transaction was for.
    let productID: String
    /// `true` for an auto-renewable subscription, `false` for a one-off purchase (lifetime).
    let isSubscription: Bool
    /// When a subscription lapses. `nil` for a purchase that never expires.
    let expirationDate: Date?
    /// Set when Apple took the purchase back (a refund). Such a transaction grants nothing.
    let revocationDate: Date?

    init(
        productID: String,
        isSubscription: Bool,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil
    ) {
        self.productID = productID
        self.isSubscription = isSubscription
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
    }
}

extension SubscriptionStore {
    /// The moment access runs out, given everything the App Store says this person owns.
    ///
    /// The rules, in one place:
    /// - a revoked (refunded) transaction grants nothing and is skipped;
    /// - a one-off purchase — the lifetime product — maps to `.distantFuture`;
    /// - a subscription maps to its expiration date;
    /// - a subscription with no expiration date contributes nothing, because Nivli would
    ///   rather fail open than shield someone on a date it had to invent;
    /// - with several entitlements the latest date wins.
    ///
    /// A date in the past is returned as it is, rather than being folded into `nil`. The one
    /// comparison against "now" lives in `ShieldPolicy`, so the stored value keeps saying
    /// *when* access ended and every part of the app reaches the same answer from it.
    nonisolated static func validUntil(entitlements: [EntitlementSnapshot]) -> Date? {
        var latest: Date?
        for entitlement in entitlements where entitlement.revocationDate == nil {
            let candidate: Date? = entitlement.isSubscription
                ? entitlement.expirationDate
                : Date.distantFuture
            guard let candidate else { continue }
            latest = latest.map { max($0, candidate) } ?? candidate
        }
        return latest
    }
}
