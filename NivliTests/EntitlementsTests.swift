import Foundation
import XCTest
@testable import Nivli

/// The pure half of `SubscriptionStore`: everything the App Store says, turned into the one
/// date the rest of Nivli stores. No StoreKit here — a test process cannot mint a
/// `Transaction`, which is exactly why `EntitlementSnapshot` exists.
final class EntitlementsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_789_000_000)

    private func monthly(expires: Date?, revoked: Date? = nil) -> EntitlementSnapshot {
        EntitlementSnapshot(
            productID: AppConfig.monthlyProductID,
            isSubscription: true,
            expirationDate: expires,
            revocationDate: revoked
        )
    }

    private func lifetime(revoked: Date? = nil) -> EntitlementSnapshot {
        EntitlementSnapshot(
            productID: AppConfig.lifetimeProductID,
            isSubscription: false,
            expirationDate: nil,
            revocationDate: revoked
        )
    }

    func testNoEntitlementsMeansNobodyIsSubscribed() {
        // Arrange
        let entitlements: [EntitlementSnapshot] = []

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertNil(validUntil)
    }

    func testActiveMonthlyReturnsItsExpirationDate() {
        // Arrange
        let expires = now.addingTimeInterval(14 * 24 * 3600)

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: [monthly(expires: expires)])

        // Assert
        XCTAssertEqual(validUntil, expires)
    }

    /// An expired subscription still reports *when* it expired. Folding a past date into
    /// `nil` would throw away the only thing Settings can honestly show, and it would change
    /// nothing about the shields: `ShieldPolicy` is the one place that compares with `now`,
    /// and a date in the past reads there as `.open(.notSubscribed)`.
    func testExpiredMonthlyStillReturnsItsExpirationDateAndReadsAsNotSubscribed() {
        // Arrange
        let expired = now.addingTimeInterval(-3600)

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: [monthly(expires: expired)])
        let decision = ShieldPolicy.decision(
            makeState(entitlementValidUntil: validUntil),
            now: now,
            calendar: testCalendar
        )

        // Assert
        XCTAssertEqual(validUntil, expired)
        XCTAssertEqual(decision, .open(.notSubscribed))
    }

    func testSubscriptionWithoutAnExpirationDateGrantsNothing() {
        // Arrange
        let entitlements = [monthly(expires: nil)]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertNil(validUntil)
    }

    func testLifetimePurchaseNeverExpires() {
        // Arrange
        let entitlements = [lifetime()]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertEqual(validUntil, Date.distantFuture)
    }

    func testRevokedEntitlementsAreIgnored() {
        // Arrange
        let entitlements = [
            lifetime(revoked: now),
            monthly(expires: now.addingTimeInterval(3600), revoked: now),
        ]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertNil(validUntil)
    }

    func testRevokedLifetimeLeavesAnActiveSubscriptionStanding() {
        // Arrange
        let expires = now.addingTimeInterval(7 * 24 * 3600)
        let entitlements = [lifetime(revoked: now), monthly(expires: expires)]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertEqual(validUntil, expires)
    }

    func testTheLatestDateWinsWhenSeveralEntitlementsOverlap() {
        // Arrange
        let soon = now.addingTimeInterval(3600)
        let later = now.addingTimeInterval(30 * 24 * 3600)
        let entitlements = [
            monthly(expires: soon),
            EntitlementSnapshot(
                productID: AppConfig.yearlyProductID,
                isSubscription: true,
                expirationDate: later
            ),
        ]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertEqual(validUntil, later)
    }

    func testALifetimePurchaseOutranksAnySubscriptionDate() {
        // Arrange
        let entitlements = [monthly(expires: now.addingTimeInterval(3600)), lifetime()]

        // Act
        let validUntil = SubscriptionStore.validUntil(entitlements: entitlements)

        // Assert
        XCTAssertEqual(validUntil, Date.distantFuture)
    }
}
