# Architecture

For the next engineer. Nivli is one SwiftUI app plus two app extensions, with a folder of
shared code compiled into all three. There is no server, no account, no database and no
third-party dependency. The only network traffic is StoreKit's.

`Nivli.xcodeproj` is never committed. XcodeGen generates it from `project.yml` on the build
machine. See `Docs/CODEMAGIC.md`.

## Targets

| Target | Sources it compiles | What it is |
| --- | --- | --- |
| `Nivli` | `Nivli/**` (App, Design, Features, Services, Shared) | The iPhone app. `com.bluepenguin.nivli` |
| `NivliMonitor` | `NivliMonitor/` + `Nivli/Shared` | DeviceActivityMonitor extension. Re-applies shields at the day boundary. `…nivli.monitor` |
| `NivliShield` | `NivliShield/` + `Nivli/Shared` | ShieldConfiguration extension. Draws the screen iOS shows over a blocked app. `…nivli.shield` |
| `NivliTests` | `NivliTests/` | Unit tests over the pure logic |
| `NivliUITests` | `NivliUITests/` | One launch smoke test |

Both extensions are built with `APPLICATION_EXTENSION_API_ONLY = YES`, embed into the app,
and carry the same App Group and Family Controls entitlements. The app additionally carries
HealthKit and HealthKit background delivery.

Deployment target is iOS 18.0, iPhone only, portrait only, Swift 5 language mode.

## The App Group state

Everything Nivli knows is one `Codable` value, `NivliState`, JSON-encoded into
`UserDefaults(suiteName: "group.com.bluepenguin.nivli")` under the key `nivli.state.v1`.
Both literals live in `SharedConstants`, which is the contract between the three bundles.

| Field | Meaning |
| --- | --- |
| `onboardingComplete` | Set when the paywall succeeds. Gates routing and shielding |
| `selection` | The `FamilyActivitySelection` of opaque tokens. Nivli only ever asks whether it is empty and how many of each kind there are |
| `minimumMinutes` | Minutes a workout must reach to unlock the day. Default 20 |
| `weeklyRestDays` | `Calendar` weekday numbers, 1 = Sunday |
| `oneOffRestDays` | `Set<DayKey>` written by "take today off" |
| `workouts` | Every entry from both sources, sorted by `start`, oldest first |
| `entitlementValidUntil` | When access runs out. `nil` means never subscribed, `.distantFuture` means the lifetime purchase. Written only by `SubscriptionStore` |
| `healthEnabled` | Whether the Health permission sheet was answered yes |
| `reminderEnabled`, `reminderMinutesFromMidnight` | The evening nudge. `18 * 60` is 6:00 pm |
| `goals`, `currentFrequency`, `dailyPhoneHours` | Onboarding answers. Used for copy only, never for logic |
| `selectionOverrideForTesting` | Not in `CodingKeys`, never persisted. A test process cannot mint an `ApplicationToken`, so this is the only way to exercise `hasSelection` |

`NivliState` has a hand-written `init(from:)` that reads every key with `decodeIfPresent` and
falls back to the default. A payload from an older build, or one missing a key, still decodes
into a usable state. Nothing in this path throws to a caller.

`SharedStore` is the only reader and writer. `load()` returns a fresh default state if there
is nothing stored or the data is corrupt. `save(_:)` logs and keeps the previous value if
encoding fails. `update(_:)` is load, mutate, save, return. A missing App Group falls back to
`UserDefaults.standard` rather than crashing. `SharedStore(suiteName:)` lets tests use a
throw-away suite.

## Data flow

### a. Onboarding to paywall to shields on

```
OnboardingFlow (8 pages)
  page 5 -> ScreenTimeAuthorization.request()   -> AuthorizationCenter (.individual)
         -> familyActivityPicker                -> AppModel.applySelection(selection)
  page 6 -> AppModel.connectHealth()            -> HKHealthStore.requestAuthorization
  page 7 -> AppModel.setReminder(...)           -> UNUserNotificationCenter
  every Continue -> AppModel.update { goals, frequency, phoneHours, minimumMinutes }
                                                        |
                                                        v
                                                   SharedStore.save
  step 8 -> PaywallView(.onboarding)
              purchase / restore -> SubscriptionStore.refreshEntitlements()
                                      -> SharedStore.update { entitlementValidUntil }
                                      -> onEntitlementChange -> AppModel.recordEntitlement
              success -> AppModel.completeOnboarding()
                           -> update { onboardingComplete = true }
                                -> recompute() -> ShieldController.refresh() -> shields ON
                           -> ActivitySchedule.startDailyMonitoring()
                                -> DeviceActivityCenter, "nivli.daily", 00:00-23:59, repeats
```

### b. Manual log to unlock

```
LogWorkoutSheet "Log it"
   -> AppModel.logWorkout(kind:minutes:)
        wasLocked = decision.isLocked
        WorkoutEntry(source: .manual, day: DayKey(start))
        StreakEngine.addingWorkout(state, entry)   (pure, returns a new state)
        SharedStore.save(next)
        recompute()   -> ShieldPolicy.decision, streak, longestStreak, weekStrip
        applyShields() -> ShieldController.refresh() -> ManagedSettingsStore.clearAllSettings()
                       -> rescheduleNudge()
   -> LogResult(unlocked: wasLocked && !decision.isLocked, underMinimum:, streak:, milestone:)
   -> HomeView shows CelebrationView only when unlocked == true
```

### c. Health background delivery to unlock and notification

```
Apple Watch / Fitness / any app writes a workout to HealthKit
   |
   v  HKObserverQuery + enableBackgroundDelivery(.immediate)
iOS wakes Nivli (possibly straight into the background)
   NivliApp.init -> AppModel.prepareForLaunch() -> health.startObserving { healthDidChange }
   |
   v
AppModel.healthDidChange()
   wasLocked = decision.isLocked
   refresh():
     state = SharedStore.load()
     importHealthWorkouts():
       health.workoutsToday()                 -> [WorkoutEntry(id: HKWorkout.uuid, .health)]
       StreakEngine.mergingHealthWorkouts()    -> dedupe by UUID, returns (state, added)
       SharedStore.save(merged)
     recompute() ; applyShields()  -> shields cleared if a workout qualified
   if wasLocked && !decision.isLocked -> NotificationService.postUnlocked(streak:)
```

The observer must be registered at process launch, not from a view's `.task`, because iOS
may have launched the app in the background for exactly this delivery. That is why
`prepareForLaunch()` is called from `NivliApp.init`.

### d. Midnight re-lock

```
00:00 (and 23:59) of every day
   |
   v
iOS wakes NivliMonitor for DeviceActivityName("nivli.daily")
   DeviceActivityMonitorExtension.intervalDidStart / intervalDidEnd
      -> ShieldController().refresh()
           SharedStore.load()                       (same App Group)
           ShieldPolicy.decision(state, now: Date())
             .locked -> apply(state.selection) on ManagedSettingsStore("nivli.daily")
             .open   -> clearAllSettings()
```

The extension holds no logic of its own. The app reaches the same answer on every
foreground, so the two can never drift.

### e. Subscription lapse, failing open

```
StoreKit renewal fails, refund, or expiry
   |
   v
Transaction.updates (long-lived detached task) OR SubscriptionStore.start() on next launch
   -> refreshEntitlements()
        currentEntitlements -> [EntitlementSnapshot]  (verified only, known product ids)
        SubscriptionStore.validUntil(entitlements:)   (pure, unit-tested)
        SharedStore.update { entitlementValidUntil = until }
        onEntitlementChange(until) -> AppModel.recordEntitlement -> update -> applyShields()
   -> ShieldPolicy sees validUntil < now -> .open(.notSubscribed) -> clearAllSettings()
   -> HomeView shows SubscriptionEndedCard
```

Shields drop at the next refresh, which is an app foreground, a Health delivery, a StoreKit
update while the app is open, or the next midnight wake. They are never left on for someone
without a valid entitlement beyond that.

## ShieldPolicy

`ShieldPolicy.decision(state, now:, calendar:) -> ShieldDecision`, where `ShieldDecision` is
`.locked` or `.open(OpenReason)`. The checks run in exactly this order, and the order is
tested:

1. `entitlementValidUntil` is nil or in the past -> `.open(.notSubscribed)`
2. `!onboardingComplete` -> `.open(.notOnboarded)`
3. `!hasSelection` -> `.open(.nothingSelected)`
4. today is a rest day -> `.open(.restDay)`
5. a qualifying workout exists today -> `.open(.workedOut(entry))`
6. otherwise -> `.locked`

Every `.open` reason is a reason not to shield. Anything unusual leaves the phone alone.
Subscription is first on purpose: someone who has not paid is never told they are locked,
whatever else is true of their state. The comparison is `validUntil >= now`, so an
entitlement expiring exactly now still counts.

`AppModel.isSubscribed`, which only drives copy, uses the stricter `until > Date()`.

## StreakEngine

Pure, Foundation only, no state of its own. Every function takes a `NivliState`.

- `isRestDay(state, day:, calendar:)`: true if the day is in `oneOffRestDays`, or its
  `Calendar` weekday number is in `weeklyRestDays`.
- `qualifyingWorkout(state, day:)`: the first entry on that day with
  `minutes >= state.minimumMinutes`. Returns `nil` otherwise.
- `streak(state, today:, calendar:)`: zero when there are no workouts at all. Today counts if
  it qualifies, and its absence never breaks the streak. From yesterday backwards, a
  qualifying day adds one, a rest day bridges without adding, anything else ends the walk.
  The walk also stops once the cursor passes the earliest stored workout day.
- `longestStreak(state, calendar:)`: walks the unique qualifying days oldest first. Two of
  them belong to the same run when every day strictly between them is a rest day. Capped at
  `maximumBridgeDays = 400` so a corrupt state cannot spin.
- `weekStrip(state, today:, calendar:)`: seven `DayStatus` values, oldest first. Today is
  `.done` or `.today`, never `.missed` and never `.rest`. Earlier days are `.done`, then
  `.rest`, then `.missed`. `.future` exists for previews and is never produced here.
- `milestoneReached(streak:)`: the matching entry of `SharedConstants.streakMilestones`
  (3, 7, 14, 30, 50, 100, 365), or nil.
- `addingWorkout(state, entry)`: removes any entry with the same id, appends, re-sorts by
  `start`. Returns a new state.
- `mergingHealthWorkouts(state, entries)`: skips ids already stored and ids repeated inside
  the incoming batch, returns `(state, added)`.

`AppModel` publishes `longestStreak` as `max(StreakEngine.longestStreak(...), streak)`, so
the number on Home is never smaller than today's run.

## AppModel is the single write path

`@MainActor @Observable final class AppModel`. Views read its properties and call exactly one
of its methods. No view touches `SharedStore`, a service, or `ShieldController` directly.

Published: `state`, `decision`, `streak`, `longestStreak`, `weekStrip`, `todayWorkout`,
`monitoringError`. All are `private(set)` and refreshed by `recompute()`.

Every write goes through `update(_:)`, which is `SharedStore.update` followed by
`recompute()` and `applyShields()`. `applyShields()` calls `ShieldController.refresh` and
then `rescheduleNudge()`. `logWorkout` is the one method that saves directly, because it has
to compare the decision before and after the write to know whether to celebrate.

`resetEverything()` clears the shields, stops the DeviceActivity schedule, cancels the nudge
and wipes the App Group.

## Services and the frameworks behind them

| Type | Framework | Notes |
| --- | --- | --- |
| `ScreenTimeAuthorization` | FamilyControls | `AuthorizationCenter.requestAuthorization(for: .individual)`. `Status` includes `.unavailable(String)`, which is what the Simulator produces |
| `ShieldController` | FamilyControls, ManagedSettings | One named store, `ManagedSettingsStore(named: "nivli.daily")`, so `clearAllSettings()` is safe. An empty part of a selection is written as `nil`, not an empty set |
| `ActivitySchedule` | DeviceActivity | `DeviceActivityCenter`, name `nivli.daily`, 00:00 to 23:59, repeating. Stops the existing one first, because `startMonitoring` throws on a duplicate name |
| `HealthKitService` | HealthKit | Read-only, workouts only. `requestAccess`, `workoutsToday(calendar:)`, `startObserving(_:)` (`HKObserverQuery` plus `enableBackgroundDelivery(.immediate)`). Every failure is an empty array and a log line |
| `HealthKitMapping` | HealthKit | Pure lookup from `HKWorkoutActivityType` to one of the nine `WorkoutKind`s. Anything unrecognised is `.other` |
| `SubscriptionStore` | StoreKit 2 | Products, entitlements, purchase, restore, `Transaction.updates`. Writes `entitlementValidUntil`. Never throws at a caller |
| `Entitlements` | none | `EntitlementSnapshot` and the pure `validUntil(entitlements:)`. A test cannot mint a `Transaction`, which is the whole reason this type exists |
| `NotificationService` | UserNotifications | Two local notifications, ids `nivli.nudge` and `nivli.unlocked`. Failures are logged, never surfaced |
| `AppConfig` | none | Bundle id, product ids, support, privacy and EULA URLs, version string. No price is ever hard-coded |

## Extension safety

`Nivli/Shared` compiles into all three bundles, so it may import Foundation, FamilyControls,
ManagedSettings, DeviceActivity, UIKit and `os`, and nothing else. It must not import
SwiftUI, StoreKit or HealthKit, and must not touch `UIApplication`. Preflight check 13
enforces this by grep, and the build enforces it again through
`APPLICATION_EXTENSION_API_ONLY`.

`SharedConstants` carries `BrandColors` as plain `UIColor`s because `ShieldConfiguration`
takes `UIColor` directly. The app's SwiftUI palette is built on top of the same values in
`Nivli/Design/NivliPalette.swift`.

The shield extension reads `SharedStore` for the streak and nothing else. It never touches
StoreKit or HealthKit, and it never learns which app it is covering: iOS hands it the name.

Preflight check 7 also restricts imports across the whole tree to a known allow-list, so a
stray framework fails the build before Xcode ever sees it.

## Logging

`os.Logger`, subsystem `com.bluepenguin.nivli`, one category per concern: `app` (AppModel),
`store` (SharedStore), `shield` (ShieldController), `monitor` (the DeviceActivity extension),
`health`, `notifications`, `screen-time`, `store-kit`. Nothing identifying is ever logged.
`ShieldController` logs a decision as a fixed word such as `open/restDay`, never a workout id
or anything about the selection. `print()` is banned and preflight check 7 fails on it.

## Testing

**Unit tests** (`NivliTests`, run on Codemagic):

| File | What it covers |
| --- | --- |
| `DayKeyTests` | Construction from a date, ISO description, start of day, month, year and leap-day boundaries, weekday numbering, ordering, JSON round trip |
| `StreakEngineTests` | Streaks with gaps, today not done yet, weekly and one-off rest-day bridging, the minimum boundary, `qualifyingWorkout`, `longestStreak`, the week strip, milestones, `addingWorkout` immutability and replacement, Health merge and dedupe |
| `ShieldPolicyTests` | Each open reason, the exact order of the five checks, the expiry boundary, yesterday's workout not unlocking today |
| `SharedStoreTests` | Defaults when nothing is stored, round trip, entitlement date to the second, corrupt data, `update` semantics, reset, two stores on one suite |
| `NivliStateTests` | Total decoding (empty, partial, unknown keys), the test-only override never being encoded, `with`, `sortedWorkouts`, the onboarding enums and their copy |
| `EntitlementsTests` | `validUntil`: none, active, expired, missing expiry, lifetime, revoked, overlapping entitlements |
| `HealthKitMappingTests` | The named activity types, and everything else mapping to `.other` |
| `TestSupport` | A fixed Gregorian, New York, Sunday-first calendar and small builders, so results are identical on a laptop and a cloud Mac |

**UI test** (`NivliUITests/LaunchTests`): launches with `-nivli-reset`, which empties the App
Group before `AppModel` is built, and waits for the `onboardingPrimaryButton` identifier.

**Static checks** (`Scripts/preflight.py`, pure Python, runs on any OS with no Xcode): plists
and entitlements parse, asset catalogs point at real files, the icon is 1024 x 1024 opaque
RGB, a privacy manifest with no tracking and a UserDefaults reason exists in every shipping
bundle, review notes fit 4,000 bytes, the StoreKit configuration matches
`AppConfig.entitlementProductIDs`, listing limits, entitlement contents, extension principal
classes matching the Info.plists, the shared-code import rules, no placeholders, no secrets,
no `print()`.

**Codemagic workflows** (`codemagic.yaml`): `ios-compile` (push to main, about 8 minutes, no
Apple credentials), `ios-unit` (push to `claude/*`, adds the unit tests), `ios-verify`
(manual, adds the UI test), `ios-testflight` and `ios-appstore` (signed, need the
`appstore_credentials` group). All five run preflight first.

## How to add a setting

The checklist, in order:

1. `Nivli/Shared/NivliState.swift`: add the stored property with a default, add it to
   `CodingKeys`, and decode it with `decodeIfPresent` in `init(from:)`.
2. `Nivli/Shared/SharedConstants.swift`: add any literal choice list or default there, not
   inline.
3. If it changes whether apps are shielded, change `ShieldPolicy.decision` and say where in
   the order, or `StreakEngine` if it changes what counts. Keep both pure.
4. `Nivli/Features/Settings/SettingsSections.swift` or `SettingsView.swift`: add the row,
   with a `Binding` whose setter calls `model.update { ... }`. Never write the store from a
   view.
5. `Nivli/App/AppModel.swift`: add a method instead of a raw `update` if the change needs a
   service call, a permission, or a comparison of the decision before and after.
6. If it belongs in onboarding: add the field to `OnboardingDraft`, the gating rule to
   `OnboardingModel.canContinue`, the page to `OnboardingFlow.page`, and the copy to
   `persist()` and `loadDraft()`. `OnboardingModel.pageCount` counts the pages before the
   paywall.
7. `NivliTests`: a decode-defaults case in `NivliStateTests`, plus a case in
   `ShieldPolicyTests` or `StreakEngineTests` if the rules moved.
8. If it is visible to a person, update `Docs/PRODUCT.md` and, when it changes what a
   reviewer sees, `AppStore/REVIEW_NOTES.md`.
9. Run `python3 Scripts/preflight.py`, then push and let Codemagic compile.
