import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen iOS paints over a shielded app or site: the Nivli mark, "Move first.", and a
/// line saying what would open it.
///
/// The extension reads the shared state only for the streak. It never touches StoreKit or
/// HealthKit, and it never learns which apps were picked — iOS hands it the name to show.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(name: application.localizedDisplayName, fallback: "this app")
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration(name: application.localizedDisplayName, fallback: "this app")
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(name: webDomain.domain, fallback: "this site")
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration(name: webDomain.domain, fallback: "this site")
    }

    /// One shield, whatever is behind it.
    private func makeConfiguration(name: String?, fallback: String) -> ShieldConfiguration {
        let subject = name ?? fallback
        var subtitle = "Log a workout in Nivli to unlock \(subject) today."
        let streak = StreakEngine.streak(SharedStore.shared.load(), today: DayKey.today())
        if streak > 0 {
            subtitle += streak == 1 ? "\nStreak: 1 day. Keep it." : "\nStreak: \(streak) days. Keep it."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: BrandColors.ink,
            icon: UIImage(named: "ShieldMark"),
            title: ShieldConfiguration.Label(text: "Move first.", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: BrandColors.ink),
            primaryButtonBackgroundColor: BrandColors.mint,
            secondaryButtonLabel: nil
        )
    }
}
