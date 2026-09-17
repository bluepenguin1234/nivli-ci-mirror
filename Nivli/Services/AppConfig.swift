import Foundation

/// Identifiers and addresses the app is built against. Prices are never hard-coded; they
/// come from the App Store at run time so the storefront's own pricing is what people see.
enum AppConfig {
    static let appName = "Nivli"
    static let bundleID = "com.bluepenguin.nivli"

    /// The one plan on sale: Nivli, monthly. Must exist in App Store Connect exactly like
    /// this (it already does, from the previous Nivli; see AppStore/SUBSCRIPTION_SETUP.md).
    static let monthlyProductID = "com.bluepenguin.nivli.plus.monthly"
    /// Sold by the previous Nivli. Not offered any more, but anyone who bought one keeps
    /// access, so the entitlement check honours them.
    static let yearlyProductID = "com.bluepenguin.nivli.plus.yearly"
    static let lifetimeProductID = "com.bluepenguin.nivli.plus.lifetime"

    /// What the paywall sells.
    static let productIDs: [String] = [monthlyProductID]
    /// Everything that counts as "subscribed".
    static let entitlementProductIDs: [String] = [monthlyProductID, yearlyProductID, lifetimeProductID]

    static let supportURL = URL(string: "https://bluepenguin1234.github.io/support.html")!
    static let privacyURL = URL(string: "https://bluepenguin1234.github.io/privacy.html")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportEmail = "suchanekbs@gmail.com"

    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "3.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
