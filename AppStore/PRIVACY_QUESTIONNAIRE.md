# App Privacy questionnaire — exact answers for Nivli 3.0

Where: App Store Connect → Apps → Nivli → sidebar **App Privacy**.
Reference: Apple "App Privacy Details" (developer.apple.com/app-store/app-privacy-details/) and
App Store Connect Help "Manage app privacy".

Apple's definition that everything below rests on: **"collect" means transmitting data off the
device** in a way that lets the developer or a partner access it for longer than needed to
service the request. Data that is processed and stored only on the device is *not collected* and
does not have to be declared. Data that Apple itself collects through its own services (the App
Store, StoreKit) is Apple's to disclose, not the developer's.

Nivli 3.0 has no server and receives nothing. The only network traffic in the whole app is
StoreKit. The previous product's answers were also "Data Not Collected", but for different
reasons (it used CloudKit); none of that applies here, and this file replaces it.

---

## Step 1 — Privacy Policy

1. In the **Privacy Policy** box click **Edit**.
2. **Privacy Policy URL**: `https://bluepenguin1234.github.io/privacy.html` (the hosted
   `Web/privacy.html`; publish the new page before submitting; the address is unchanged but the
   content is not).
3. **User Privacy Choices URL**: leave blank.
4. Click **Save**.

## Step 2 — Data collection

1. Click **Get Started**.
2. Question: **"Do you or your third-party partners collect data from this app?"**
3. Choose **"No, we do not collect data from this app"**.
4. Click **Save**. There are no further questions.
5. Click **Publish** (top right) and confirm that the answers are accurate.

Result on the product page: **Data Not Collected**. "The developer does not collect any data
from this app."

## For the record — every data type, and why it is not collected

Because "No" is selected you never see these screens. If you ever have to justify the answer,
this is the table.

| Category | Nivli 3.0 | Why |
|---|---|---|
| **Health & Fitness** (fitness: workouts) | **Not collected** | With the user's permission Nivli reads **workouts only** from HealthKit: start time, duration, workout type and the workout's identifier (used to avoid counting the same session twice). It is read on the iPhone, written into the app's own App Group storage, and used to decide whether today's apps unlock. It is never transmitted, there is nowhere for it to be transmitted to, and Nivli writes nothing back to Health. Read-only access to HealthKit does not by itself make anything "collected" |
| **Health & Fitness** (health: everything else) | Not collected | Nivli requests no other HealthKit type. No heart rate, no steps, no body measurements, no sleep, no clinical records |
| Contact Info (name, email, phone, address) | Not collected | No account, no sign-up, no form that sends anything anywhere |
| Financial Info (payment info) | Not collected | Apple processes the subscription; the app never sees card or billing details |
| Location (precise or coarse) | Not collected | Location is never requested. Workouts imported from Health carry no route or location data into Nivli |
| Sensitive Info | Not collected | Not used |
| Contacts | Not collected | The Contacts framework is not linked |
| **Screen Time selection** (the apps, categories and websites the user picks) | **Not collected**, and not a declarable data type | Apple's `FamilyActivityPicker` hands the app a `FamilyActivitySelection` of **opaque tokens**. A token is resolvable only by iOS. Nivli cannot read an app's name, bundle identifier or icon from one, and stores the tokens solely so `ManagedSettings` can re-apply the same shield. They are written to the App Group container on the device and are transmitted nowhere |
| **Screen Time usage data** | Not collected | Nivli never requests or receives usage reports. It uses `FamilyControls` + `ManagedSettings` (shielding) and a `DeviceActivityMonitor` schedule (a midnight re-lock). It does not read how long any app is used, which apps are opened, or any DeviceActivity report |
| User Content (the workout log: date, length, kind, source) | Not collected | Typed by the user or imported from Health, stored only in the App Group container on the device |
| User Content (settings, streak, rest days, onboarding answers) | Not collected | Same storage, same device, never transmitted |
| User Content (photos, audio, other) | Not collected | Nivli has no camera, photo, microphone or speech feature |
| Browsing History | Not collected | No web content, no web view |
| Search History | Not collected | There is no search |
| Identifiers (user ID, device ID) | Not collected | None is created or read. There is no advertising identifier, no vendor identifier use, no account |
| Purchases (purchase history) | Not collected | The app asks StoreKit whether the subscription is valid and keeps only a valid-until date on the device. It stores no purchase record off device |
| Usage Data (product interaction, advertising data) | Not collected | No analytics of any kind, no ads |
| Diagnostics (crash, performance, other) | Not collected | No crash-reporting SDK. Apple's own opt-in crash reports go to Apple under the user's iOS analytics setting and are not the developer's collection to declare |
| Surroundings / Body | Not collected | Not used |
| Other Data | Not collected | — |

## "Data Linked to You" and "Data Used to Track You"

Both labels only appear when something is collected. Nivli collects nothing, so:

- **Data Linked to You**: none. Nothing reaches the developer, so nothing can be linked to an
  identity. There is no user ID, account or device identifier of ours.
- **Data Used to Track You**: none. Apple defines tracking as linking app data about a user or
  device with third-party data for advertising or measurement, or sharing it with a data broker.
  Nivli has no advertising, no analytics, no third-party SDKs, and nothing leaves the device. The
  app therefore does **not** call App Tracking Transparency and must not include
  `NSUserTrackingUsageDescription`.

## The HealthKit rules still apply, whatever the label says

Apple imposes obligations on HealthKit data that are separate from the App Privacy answers, and
Nivli meets all of them. Keep it that way.

- **Never used for advertising, marketing or similar services** (App Store Review Guideline 5.1.3
  and the HealthKit terms). Nivli has no advertising or marketing of any kind.
- **Never disclosed to a third party**, sold, or shared for data mining. There is no third party.
  The whole app target contains no `URLSession`, no `URLRequest` and no socket; the only network
  traffic is StoreKit's.
- **A clear purpose string.** `NSHealthShareUsageDescription` explains that Nivli reads workouts
  to decide whether today's apps unlock. `NSHealthUpdateUsageDescription` is **not** set, because
  Nivli never writes to Health.
- **Only what is needed.** The read request covers workouts and nothing else.
- **The privacy policy names Health.** `Web/privacy.html` has a section on it, saying what is
  read, that it is read-only, that it stays on the device, and how to revoke it in
  Health → Sharing → Apps → Nivli.
- **Not for a person under 13 without consent**: Nivli is a general-purpose app for adults
  managing their own screen time, is not directed at children, and collects nothing from anyone.

The same holds for the Screen Time API: guideline 5.4 requires that an app using `FamilyControls`
use it for the stated purpose only and not sell or share any of it. Nivli shields the user's own
selection on the user's own device and reports nothing anywhere.

## Notes on the Apple technologies the app uses

**HealthKit**: optional, read-only, workouts only, with background delivery so a watch workout
can unlock the apps while the phone is in a pocket. The delivery wakes the app on the device with
the same workout data; nothing is transmitted. Entitlements:
`com.apple.developer.healthkit` and `com.apple.developer.healthkit.background-delivery`.

**FamilyControls / ManagedSettings / DeviceActivity**: authorization is requested with
`.individual`, for the device's own user. `ManagedSettingsStore` applies the shield;
`DeviceActivityCenter` runs one daily schedule so `NivliMonitor` can re-apply it at midnight;
`NivliShield` draws the branded lock screen and reads only the streak from the App Group. None of
the three sends anything anywhere, and none of them is a data-collection answer in App Store
Connect. The entitlement `com.apple.developer.family-controls` is on all three bundles.

**Notifications**: local only (`UNUserNotificationCenter`): "apps unlocked" and the optional
evening nudge. There is no push server and no APNs token. Optional; refusing changes nothing else.

**StoreKit (In-App Purchase)**: the subscription is processed by Apple. The app receives a
transaction status and stores only a valid-until date on the device. Payment details, the Apple
Account and receipts are Apple's data, and Apple's guidance is that you are not responsible for
disclosing data collected by Apple.

**App Group (`group.com.bluepenguin.nivli`)**: the app and both extensions read and write one
JSON blob in shared `UserDefaults`: the selection tokens, the workout log, the streak and the
settings. On the device, in the app's own container. Not a collection.

**Backups**: the state file is excluded from iCloud Backup and computer backups (it can hold
workouts read from Apple Health, which Apple's HealthKit terms keep out of iCloud). Nothing is
transferred anywhere.

## Privacy manifest (for the developer, not App Store Connect)

All three bundles ship `PrivacyInfo.xcprivacy` with:

- `NSPrivacyTracking` = false
- `NSPrivacyTrackingDomains` = empty
- `NSPrivacyCollectedDataTypes` = empty
- `NSPrivacyAccessedAPITypes`: only the required-reason APIs actually used, which is
  **UserDefaults** (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `1C8F.1`, App Group access
  shared with the extensions). HealthKit, FamilyControls, ManagedSettings and DeviceActivity are
  not on Apple's required-reason list and add nothing here. No third-party SDKs means no
  third-party manifests to include.

`Scripts/preflight.py` check 4 fails the build if any bundle loses its manifest, declares
tracking, or drops the UserDefaults reason.

## Keep it true

"Data Not Collected" holds for 3.0 because the app has no network code of its own at all. If a
future version adds anything that sends data to the developer or a partner (crash reporting,
analytics, a server, a sync service), come back to **App Privacy → Edit** and change the answer
*before* that version ships. Data-type answers publish immediately without a new build; a change
to the privacy policy URL ships with the next version.
