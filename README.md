# Nivli

**Move first. Then scroll.** Nivli locks the social apps you choose until you have logged a
workout today, by hand or straight from Apple Health. Every day you move, the streak grows.

- iPhone · iOS 18+ · SwiftUI · Screen Time API (FamilyControls, ManagedSettings,
  DeviceActivity) · HealthKit (read-only workouts) · StoreKit 2 · UserNotifications
- No account, no server, no analytics, no third-party code. Everything stays on the iPhone.
- One plan: Nivli Monthly, $2.99 / month, after an eight-page onboarding.
- Built and shipped entirely from the cloud (Codemagic); no Mac needed.

| Doc | What it's for |
| --- | --- |
| [Docs/HANDOFF.md](Docs/HANDOFF.md) | **Start here.** Everything the owner has to do, in order, to ship 3.0 |
| [Docs/PRODUCT.md](Docs/PRODUCT.md) | What the app is, every screen, how locking and streaks work, in plain language |
| [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) | How the code is organised and how data flows between the app and its extensions |
| [Docs/DECISIONS.md](Docs/DECISIONS.md) | Why it is built this way, and what each decision costs |
| [Docs/CODEMAGIC.md](Docs/CODEMAGIC.md) | Build, test, sign and upload to TestFlight without a Mac |
| [Docs/RELEASE_CHECKLIST.md](Docs/RELEASE_CHECKLIST.md) | Every step from here to "Submit for Review" |
| [Docs/DEVICE_TEST.md](Docs/DEVICE_TEST.md) | What to try on a real iPhone before submitting |
| [Docs/superpowers/specs/](Docs/superpowers/specs/) | The design spec the build followed |
| [AppStore/](AppStore/) | Listing copy, review notes, privacy answers, subscription setup, screenshots plan |
| [Web/](Web/) | Privacy policy, support page and landing page to host |
| [Brand/](Brand/) | Icon, mark and brand guide |

## Repository layout

```
project.yml            XcodeGen definition (generates Nivli.xcodeproj on the build machine)
codemagic.yaml         Cloud build / test / TestFlight / App Store workflows
.github/workflows/     Manual GitHub Actions verification (ios.yml)
Nivli/                 The app
  App/                 NivliApp (entry), RootView (routing), AppModel (the one object screens use)
  Design/              Theme, palette, components, the "Ni" mark, haptics
  Features/            Onboarding, Paywall, Home, LogWorkout, Settings
  Services/            StoreKit, HealthKit, Screen Time authorization, notifications, AppConfig
  Shared/              Compiled into the app AND both extensions: state, store, streaks, shield policy
NivliMonitor/          DeviceActivityMonitor extension: re-locks the apps at midnight
NivliShield/           ShieldConfiguration extension: the branded "Move first." screen over a blocked app
NivliTests/            Unit tests for the shared logic, entitlements and Health mapping
NivliUITests/          One launch smoke test
Config/Nivli.storekit  StoreKit test configuration (simulator purchases)
Scripts/               preflight.py (packaging checks), test-ios.sh, normalize_p8.py, render_icon.py
```

## Working on it

1. Edit Swift under `Nivli/`, `NivliMonitor/`, `NivliShield/` and tests under `NivliTests/`.
2. Run `python3 Scripts/preflight.py` (works on Windows, macOS, Linux; no Xcode).
3. Push to `main` (or a `claude/*` branch): Codemagic compiles the app and both extensions
   on Apple's toolchain; `claude/*` branches also run the unit tests.
4. Never commit `Nivli.xcodeproj`; XcodeGen regenerates it from `project.yml`.

## How it works, in one paragraph

Onboarding asks for Screen Time access and lets the person pick apps with Apple's picker
(Nivli only receives opaque tokens). After the paywall, the app writes the selection, the
subscription's expiry and the settings into an App Group and applies a *shield* to those apps
through a named `ManagedSettingsStore`. A `DeviceActivityMonitor` extension wakes at 00:00
every day and re-applies the shield. Logging a workout (manually, or when a Health workout at
or above the minimum is imported, including in the background) clears the shield until the
next midnight and grows the streak. The shield is *never* applied when the subscription is not
valid, onboarding is unfinished, nothing is selected, or it is a rest day.
