# Building, testing and shipping without a Mac (Codemagic)

Everything below is done in a web browser. Names in **bold** are things you click or type.
If you set Codemagic up for the previous Nivli (the `hmm123` repository), the account, the
`appstore_credentials` variable group and the certificate all carry over; only §1 and §2
are new.

## 1. Connect the repository (once, ~5 minutes)

1. Go to https://codemagic.io and sign in with GitHub.
2. **Add application** → **GitHub** → give Codemagic access to `bluepenguin1234/nivli`
   (if you chose "Only select repositories" before, add this repository to the list in
   GitHub → Settings → Applications → Codemagic → Configure).
3. Pick the repository, choose **Codemagic YAML** as the project type, and finish.
4. **Start new build** → branch **main** → workflow **iOS Compile — Fast check** → **Start
   new build**. About 8 minutes. It compiles the app and both extensions on Apple's
   toolchain and needs no Apple credentials.
5. When it is green, run **iOS Unit — Build + unit tests** the same way (about 15 minutes).

### Reading a failed build

Open the build, expand the red step, and look for the first line containing `error:`.
Copy that line (with the file name next to it) into a message to your engineering session;
it is enough to fix the problem. Warnings can be ignored.

## 2. Apple Developer portal: capabilities (once, ~15 minutes, plus Apple's approval)

Codemagic creates App IDs on the first signed build but never switches on capabilities, and
a provisioning profile without them fails at signing with "entitlement not supported".

### 2a. Family Controls (Distribution): ask Apple first

The Screen Time API needs an entitlement that Apple grants per app. Development builds get
it automatically; **App Store and TestFlight builds only get it after Apple approves a
request**, which typically takes a few days to a few weeks.

1. Go to https://developer.apple.com/contact/request/family-controls-distribution (sign
   in with the Account Holder Apple Account).
2. Fill in: app name **Nivli**, bundle ID **com.bluepenguin.nivli**, and in the description
   explain: *"Nivli is a personal screen-time app. The user picks apps with
   FamilyActivityPicker on their own iPhone (individual authorization) and Nivli shields them
   with ManagedSettings until the user logs a workout for the day. A DeviceActivityMonitor
   extension (com.bluepenguin.nivli.monitor) re-applies the shield at midnight and a
   ShieldConfiguration extension (com.bluepenguin.nivli.shield) draws the shield. No
   parental or remote-device features; nothing is reported off the device."*
   Mention all three bundle IDs so the extensions are covered.
3. Wait for Apple's email. After approval, **Family Controls (Distribution)** appears in
   the capability list of the App IDs below.

### 2b. Register the App IDs and tick the capabilities

1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles** →
   **Identifiers**. The App Group **group.com.bluepenguin.nivli** and the App ID
   **com.bluepenguin.nivli** already exist from the previous Nivli.
2. Open **com.bluepenguin.nivli** and tick: **App Groups** (configure →
   group.com.bluepenguin.nivli), **HealthKit**, **Family Controls (Distribution)** (after
   2a). Untick iCloud and Push Notifications if they are still ticked; 3.0 does not use
   them. **Save** → **Confirm**.
3. **+** → **App IDs** → App → Description **Nivli Monitor**, Bundle ID Explicit
   **com.bluepenguin.nivli.monitor** → tick **App Groups** and **Family Controls
   (Distribution)** → Continue → Register → open it → configure App Groups →
   group.com.bluepenguin.nivli → Save.
4. Repeat for **Nivli Shield**, **com.bluepenguin.nivli.shield**.
5. The old **com.bluepenguin.nivli.widgets** and **com.bluepenguin.nivli.share** App IDs
   can stay; nothing uses them any more.

## 3. App Store Connect API key (once, ~3 minutes)

Skip if the `appstore_credentials` group already exists in Codemagic from the previous app.

1. https://appstoreconnect.apple.com → **Users and Access** → **Integrations** → **App
   Store Connect API** → **Team Keys** → **+**. Name **Codemagic**, Access **App Manager**.
2. **Download API Key** (offered once; keep the `.p8`). Note the **Key ID** and the
   **Issuer ID**.

## 4. Give Codemagic the key (once, ~3 minutes)

Skip if already done. In Codemagic → the app → **Environment variables**, group
**appstore_credentials**, each **Secure**:

- `APP_STORE_CONNECT_PRIVATE_KEY`: the whole `.p8` file, BEGIN to END lines included.
- `APP_STORE_CONNECT_KEY_IDENTIFIER`: the Key ID.
- `APP_STORE_CONNECT_ISSUER_ID`: the Issuer ID.
- `CERTIFICATE_PRIVATE_KEY`: the RSA key Codemagic uses to create and reuse the Apple
  Distribution certificate (`nivli_certificate_key.pem` on the Desktop from the previous
  set-up; the whole file, BEGIN to END).

Never put these values into GitHub or a chat.

## 5. The App Store Connect record

The app record **Nivli** (bundle ID com.bluepenguin.nivli, SKU nivli-ios) already exists.
3.0 replaces the previous product under it: create a new version **3.0.0** on the App Store
page when you are ready, and follow `AppStore/SUBSCRIPTION_SETUP.md` for the subscription
changes (rename the monthly plan, remove the yearly and lifetime plans from sale).

## 6. First TestFlight build

Codemagic → **Start new build** → workflow **iOS Release — Sign + TestFlight** → Start.
About 20 minutes. The build appears in App Store Connect → **TestFlight** after Apple
processes it (5–30 minutes). Install the **TestFlight** app on your iPhone, add yourself as
an internal tester, install Nivli, and walk through `Docs/DEVICE_TEST.md`.

Build numbers are `100 + Codemagic's counter`, so they never collide with the previous
app's builds.

## 7. Submitting

Fill in the metadata from `AppStore/LISTING.md`, the privacy answers from
`AppStore/PRIVACY_QUESTIONNAIRE.md`, screenshots per `AppStore/SCREENSHOTS.md`, the review
notes from `AppStore/REVIEW_NOTES.md`, then run **iOS Release — Submit build to App Store
Connect** (or pick the TestFlight build on the version page) and press **Submit for
Review**. Full order of operations: `Docs/RELEASE_CHECKLIST.md`.

## GitHub Actions (optional)

`.github/workflows/ios.yml` runs the same verification on GitHub's Macs, started by hand
from the Actions tab. On a private repository this needs Actions billing enabled (GitHub →
Settings → Billing → Spending limits → set a small limit for Actions); macOS minutes count
10×. Codemagic is sufficient on its own.
