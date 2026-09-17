# Nivli 3.0 — owner handoff

Everything the build team could do from this Windows machine is done and pushed to
`main` on https://github.com/bluepenguin1234/nivli. What is left needs your Apple, Codemagic
and GitHub accounts. Do the steps in order; each one says how long it takes and what you
should see when it worked. Nothing here needs a Mac or any code.

**Where things stand.** The app is complete: 8-page onboarding, paywall, Home, log workout,
Settings, the midnight re-lock extension and the branded shield, unit tests, store copy, web
pages, and the cloud build pipeline. It passes the repository's own packaging checks, and on
17 September 2026 it was **compiled on a GitHub-hosted Mac (Xcode 26.6)**: the app and both
extensions built with no errors, all 96 unit tests passed, and the launch smoke test passed
on an iPhone simulator. What no cloud Mac can prove is the Screen Time behaviour itself,
which only exists on a real iPhone; that is the TestFlight step below.

---

## 1. Compile it on Codemagic (15 minutes, free)

The free Codemagic plan includes 500 build minutes a month; a compile check uses about 8.

1. https://codemagic.io → sign in with GitHub → **Add application** → GitHub →
   `bluepenguin1234/nivli` → **Codemagic YAML** → finish. (If Codemagic cannot see the
   repository: GitHub → Settings → Applications → Codemagic → Configure → add `nivli`.)
2. **Start new build** → branch `main` → workflow **iOS Compile — Fast check** → Start.
3. Green: continue to step 2. (It was green on GitHub's Mac with the same Xcode version,
   so expect green here too.) Red: open the build, expand the red step, copy the first
   line containing `error:` (and the file name next to it) into a new chat with the
   engineering session, push the fix, re-run.
4. Then run **iOS Unit — Build + unit tests** the same way (about 15 minutes). Green means
   every rule about streaks, rest days, shields and entitlements passes on Apple's toolchain.

## 2. Ask Apple for the Family Controls entitlement (10 minutes, then wait days to weeks)

This is the long pole. Screen Time blocking needs an entitlement Apple grants per app for
App Store distribution. Without it the signed build fails at the signing step. Submit this
today, before anything else that has a wait.

1. https://developer.apple.com/contact/request/family-controls-distribution (Account
   Holder Apple Account).
2. App name **Nivli**, bundle ID **com.bluepenguin.nivli**. Description (paste):

   > Nivli is a personal screen-time app. The user picks apps with FamilyActivityPicker on
   > their own iPhone (individual authorization) and Nivli shields them with ManagedSettings
   > until the user logs a workout for the day. A DeviceActivityMonitor extension
   > (com.bluepenguin.nivli.monitor) re-applies the shield at midnight and a
   > ShieldConfiguration extension (com.bluepenguin.nivli.shield) draws the shield. No
   > parental or remote-device features; nothing is reported off the device. Please cover
   > all three bundle IDs.

3. When Apple's approval email arrives, do step 3. If Apple asks questions, answer from
   `AppStore/REVIEW_NOTES.md`.

## 3. Switch on the capabilities in the Apple Developer portal (10 minutes, after step 2)

`Docs/CODEMAGIC.md` §2b has the exact clicks. In short: App ID **com.bluepenguin.nivli** →
tick **App Groups** (group.com.bluepenguin.nivli), **HealthKit**, **Family Controls
(Distribution)**; untick iCloud and Push Notifications. Register two new App IDs,
**com.bluepenguin.nivli.monitor** and **com.bluepenguin.nivli.shield**, each with **App
Groups** (same group) and **Family Controls (Distribution)**.

## 4. App Store Connect: the subscription and the agreement (15 minutes)

`AppStore/SUBSCRIPTION_SETUP.md` has the clicks. In short:

1. **Business → Agreements**: Paid Apps must show *Active* (it did for the old app; check).
2. **Apps → Nivli → Subscriptions → Nivli+ group → Nivli+ Monthly**: rename the display
   name to **Nivli Monthly**, description **Unlock your apps by moving first**, confirm
   **$2.99 / 1 month**, add a review screenshot (the paywall) and review note.
3. Remove **Nivli+ Yearly** and **Nivli+ Lifetime** from sale. Do not delete them; anyone
   who bought one keeps access in 3.0.

## 5. Codemagic credentials (5 minutes, only if the old ones are gone)

The variable group `appstore_credentials` from the previous Nivli works as is. If Codemagic
was set up fresh, follow `Docs/CODEMAGIC.md` §3–4: an App Store Connect API key
(Users and Access → Integrations) and `nivli_certificate_key.pem` from your Desktop.

## 6. TestFlight build and device test (30 minutes, after steps 1–5)

1. Codemagic → **Start new build** → **iOS Release — Sign + TestFlight** → Start.
2. App Store Connect → TestFlight → install on your iPhone via the TestFlight app.
3. Walk through `Docs/DEVICE_TEST.md` top to bottom. The three that matter most: a picked
   app shows the "Move first." shield; logging a 30-minute workout opens it; the next
   morning it is locked again.
4. Anything wrong → describe it to the engineering session with the step number.

## 7. Publish the web pages (5 minutes, the day you submit)

The app links to https://bluepenguin1234.github.io/privacy.html and `/support.html`. The
three files in `Web/` replace the old app's pages. Before copying, search each file for
`<<OWNER` and fill in your legal name and (after release) the App Store link. Then, in a
terminal on this PC:

```bash
git clone https://github.com/bluepenguin1234/bluepenguin1234.github.io.git "$TEMP/pages" && cp Web/*.html "$TEMP/pages/" && git -C "$TEMP/pages" add -A && git -C "$TEMP/pages" commit -m "Nivli 3.0 pages" && git -C "$TEMP/pages" push
```

(Run it from the `nivli` folder in Git Bash, which is what this app's terminal uses.)

Or open the `bluepenguin1234.github.io` repository on github.com and upload the three files
through **Add file → Upload files**. They go live within a minute.

## 8. App Store listing and submission (45 minutes)

`Docs/RELEASE_CHECKLIST.md` is the ordered list. Sources for every field:

| Field | File |
|---|---|
| Name, subtitle, promo text, description, keywords, category, age rating | `AppStore/LISTING.md` |
| What's New | `AppStore/RELEASE_NOTES.md` |
| Screenshots (6 per size, from the TestFlight build on your iPhone) | `AppStore/SCREENSHOTS.md` |
| App Privacy answers | `AppStore/PRIVACY_QUESTIONNAIRE.md` |
| App Review notes and contact | `AppStore/REVIEW_NOTES.md` |

Create version **3.0.0** on the App Store page, fill it in, run **iOS Release — Submit
build to App Store Connect** on Codemagic (or attach the TestFlight build), then **Submit
for Review**. Delete every old 2.x screenshot first; the reviewer compares screenshots to
the app.

## 9. After approval

- Keep an eye on App Store Connect → **Crashes** for the first week.
- Optional 7-day free trial: an App Store Connect-only change (SUBSCRIPTION_SETUP.md, last
  section); the paywall shows it automatically.
- Optional GitHub Actions: enable Actions billing with a small limit and the manual
  workflow in `.github/workflows/ios.yml` gives a second compile check.

---

## Decisions made on your behalf (change any of them by asking)

1. Same bundle ID and App Store record, version 3.0.0, replacing the memory app.
2. The existing $2.99 monthly product is reused; yearly and lifetime are retired but honoured.
3. Hard paywall after onboarding; no free tier.
4. Manual logs are honor system; a workout counts at 20 minutes by default (10–60 in Settings).
5. Weekly rest days and "take today off" exist and never break the streak.
6. If the subscription lapses, onboarding is unfinished or nothing is picked, nothing is
   ever locked (the app fails open on purpose; Apple would reject anything else).
7. iOS 18 minimum, iPhone only, dark by default with a light option.

## Things that cannot be verified without a real iPhone

- Anything Screen Time: the simulator has no Screen Time, so only a real iPhone (step 6)
  proves the shield, the picker and the midnight re-lock.
- Apple Health background unlock needs an Apple Watch or the Fitness app on the device.
- The App Store price string, which comes from the storefront at run time.
