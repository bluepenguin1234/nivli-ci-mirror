import SwiftUI

/// The three promises the paywall makes, in the order they matter.
struct PaywallBenefits: View {
    var body: some View {
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
}

/// The plan on sale: a glass pane edged in mint, with the price as the only lit thing on it.
/// Every number comes from the storefront, never from a literal, so the caller hands in the
/// lines `SubscriptionStore` built from the `Product`.
struct PaywallPlanCard: View {
    let priceLine: String
    var introductoryOfferLine: String? = nil

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                TelemetryLabel("Monthly", tint: .accentColor)
                Text(AppConfig.appName)
                    .font(.title3.weight(.bold))
                Text(priceLine)
                    .font(Theme.numeral(.title2))
                    .foregroundStyle(Color.accentColor)
                    .modifier(Theme.glow(.accentColor, radius: 18))
                if let introductoryOfferLine {
                    Text(introductoryOfferLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Chip(text: "Cancel anytime", systemImage: "checkmark.circle.fill", tint: .accentColor)
                    .padding(.top, 2)
            }
        }
        // The one card in the app that is edged in the accent rather than a neutral hairline:
        // it is the thing the screen exists to sell.
        .overlay(
            RoundedRectangle(cornerRadius: Theme.glassRadius, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
        )
    }
}

/// The renewal terms App Review expects on the same screen as the price, plus the two links.
struct PaywallLegal: View {
    var body: some View {
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
}
