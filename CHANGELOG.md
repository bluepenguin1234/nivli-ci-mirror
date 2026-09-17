# Changelog

All notable changes to Nivli are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.0] — 2026-09-16

Nivli 3.0 is a new product. It keeps the App Store record, the bundle identifier
`com.bluepenguin.nivli` and the subscription group "Nivli+" of the app that came before it, and
nothing else. The previous Nivli was a memory for the upkeep of life; this one locks the apps you
choose until you have worked out today.

### Added

- Screen Time locking. The apps, categories and websites chosen in Apple's `FamilyActivityPicker`
  are shielded with `ManagedSettings`. Authorization is requested for the device's own user
  (`individual`), on first run.
- Manual workout logging. Nine kinds, a duration, two taps. A workout at or over the minimum
  unlocks the day until midnight.
- Apple Health, optional and read-only: workouts only, deduplicated by identifier, with background
  delivery so a watch workout unlocks the apps without opening the app. Nothing is written to
  Health.
- Minimum workout length, settable at 10, 15, 20, 30, 45 or 60 minutes. Default 20.
- Streaks: current and longest, with a seven-dot week strip and milestone celebrations at 3, 7,
  14, 30, 50, 100 and 365 days.
- Weekly rest days and a one-off "take today off". Nothing is locked on a rest day and the streak
  is neither broken nor grown.
- A midnight re-lock. The `NivliMonitor` device-activity extension re-applies the shields at the
  start of every day.
- `NivliShield`, the branded lock screen shown over a blocked app.
- An optional evening reminder, as a local notification, if the day is still open.
- Eight-page onboarding ending in the paywall, and a Settings screen covering the selection, Apple
  Health, the minimum, rest days, reminders, appearance, the subscription and a reset.
- New website: `Web/index.html`, `Web/privacy.html`, `Web/support.html`.
- New App Store metadata for 3.0.0 in `AppStore/`.

### Changed

- One plan: `com.bluepenguin.nivli.plus.monthly` at $2.99 a month, behind a hard paywall at the
  end of onboarding. There is no free tier.
- Subtitle and positioning: "Work out to unlock your apps". Move first. Then scroll.
- Primary category is now Health & Fitness, with Productivity secondary.
- Minimum iOS version raised to 18.0. iPhone only, portrait only.
- The privacy policy is rewritten for this product and applies to version 3.0 and later. The
  previous policy no longer applies.

### Deprecated

- `com.bluepenguin.nivli.plus.yearly` ($19.99) and `com.bluepenguin.nivli.plus.lifetime` ($39.99)
  are removed from sale in App Store Connect. They are still honoured as valid entitlements, so
  anyone who bought one keeps access through Restore Purchases.

### Removed

- Everything from the previous product: things, logs, details, photos and the text read from them,
  the timeline, Siri and App Intents, widgets, Control Center and Lock Screen entries, Visual
  Intelligence, "Say it to Nivli", CSV export, and Household sharing through CloudKit.
- CloudKit, the microphone, speech recognition, the camera and the photo picker are no longer used
  at all, and their permissions are no longer requested.

### Security

- Fail open by design: no shield is ever applied unless the subscription is valid, onboarding is
  complete and a selection exists. Deleting the app removes the shields.
- The app selection reaches Nivli as opaque tokens, so it never learns which apps were chosen.
- No account, no server, no analytics and no third-party SDKs. The only network traffic is
  StoreKit. App Privacy answer: Data Not Collected.
- Privacy manifests in all three bundles declare no tracking and no collected data types.
