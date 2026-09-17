import Foundation
import UIKit

/// The handful of literals the app and both extensions have to agree on exactly.
///
/// Anything here is a contract between three bundles: change a value and the monitor
/// extension stops seeing the app's state, or the shield store stops matching the one the
/// app writes to. Nothing else in `Shared` hardcodes these strings.
enum SharedConstants {
    /// The App Group whose container carries the `NivliState` file between the app, the
    /// DeviceActivity monitor and the shield configuration extension.
    static let appGroupID = "group.com.bluepenguin.nivli"

    /// The file the encoded `NivliState` lives in, inside the App Group container. Versioned
    /// so a future breaking shape can migrate instead of failing to decode.
    static let stateFileName = "nivli-state-v1.json"

    /// The name of the `ManagedSettingsStore` that carries Nivli's shields. Using a named
    /// store (rather than the unnamed one) keeps Nivli's settings separate from anything
    /// else on the device and lets `clearAllSettings()` be safe.
    static let managedSettingsStoreName = "nivli.daily"

    /// The name of the repeating `DeviceActivity` schedule that re-locks at midnight.
    static let dailyActivityName = "nivli.daily"

    /// The minimum-duration choices offered in onboarding and Settings, in minutes.
    static let minimumMinuteChoices = [10, 15, 20, 30, 45, 60]

    /// The minimum duration a new install starts with, in minutes.
    static let defaultMinimumMinutes = 20

    /// Streak lengths that earn a celebration, in ascending order.
    static let streakMilestones = [3, 7, 14, 30, 50, 100, 365]
}

/// The brand palette as plain `UIColor`s, safe in an extension-only target.
///
/// `NivliPalette` builds the app's SwiftUI surfaces on top of these; the shield extension
/// needs the raw colours because `ShieldConfiguration` takes `UIColor` directly.
enum BrandColors {
    /// `#142B39` — the ink the mark is drawn in and the locked ring uses.
    static let ink = UIColor(red: 0x14 / 255, green: 0x2B / 255, blue: 0x39 / 255, alpha: 1)

    /// `#5EDCC0` — the accent: unlocked rings, primary buttons, the streak flame.
    static let mint = UIColor(red: 0x5E / 255, green: 0xDC / 255, blue: 0xC0 / 255, alpha: 1)

    /// `#11665D` — the deeper teal that reads as an accent on light backgrounds.
    static let tealLight = UIColor(red: 0x11 / 255, green: 0x66 / 255, blue: 0x5D / 255, alpha: 1)

    /// `#08131C` — the outer edge of the night canvas gradient.
    static let nightEdge = UIColor(red: 0x08 / 255, green: 0x13 / 255, blue: 0x1C / 255, alpha: 1)

    /// `#10242F` — the centre glow of the night canvas gradient.
    static let nightGlow = UIColor(red: 0x10 / 255, green: 0x24 / 255, blue: 0x2F / 255, alpha: 1)

    /// `#10202B` — a card or list row on the night canvas.
    static let nightSurface = UIColor(red: 0x10 / 255, green: 0x20 / 255, blue: 0x2B / 255, alpha: 1)

    /// `#162B3B` — a surface that sits on top of another surface.
    static let nightRaised = UIColor(red: 0x16 / 255, green: 0x2B / 255, blue: 0x3B / 255, alpha: 1)
}
