# Nivli — App Store listing (v3.0.0, submission copy)

Source of truth: `Docs/superpowers/specs/2026-09-16-nivli-move-first-design.md`. Limits checked
against App Store Connect Help (App information: name 2–30 chars, subtitle 30; Platform version
information: promotional text 170 chars, description 4000 chars, keywords 100 bytes, review
notes 4000 bytes). `Scripts/preflight.py` check 10 measures the fenced blocks below.

Fields marked `<<OWNER: …>>` (legal name, review contact) must be filled in by the owner before
submission.

**This version replaces a different product.** The App Store record and bundle ID
(`com.bluepenguin.nivli`) stay the same; everything a customer sees changes. The listing below
replaces all of the 2.x metadata.

---

## Name

```
Nivli
```

## Subtitle

```
Work out to unlock your apps
```

Note: 28 characters, of 30. The 1.x/2.x subtitles ("Remember when.", "The memory Siri uses.")
belong to the old product and must be replaced.

## Promotional text

```
Pick the apps that eat your evenings. Nivli holds them until you have moved. Log a workout, or let Apple Health do it for you, and they open until midnight.
```

170 max, editable at any time without a new build.

## Description

```
Nivli locks the apps you choose until you have worked out today.

Pick the ones that take your evenings. From midnight they sit behind a lock screen. Log a workout and they open for the rest of the day. Tomorrow they are waiting again.

Move first. Then scroll.

HOW IT WORKS
1. Choose the apps that wait. Apple's own picker, so you can pick single apps, whole categories, or websites.
2. Move. Log a workout in two taps, or connect Apple Health and let a run, a lift or a class do it for you.
3. Then scroll. Your apps open until midnight and the streak goes up one.

LOG IT IN TWO TAPS
Pick a kind, pick a length, tap once. Nine kinds: run, walk, strength, cycle, swim, yoga, HIIT, sport, other. You set the minimum that counts, from 10 minutes to an hour, and 20 is the default. A shorter session is still kept in your history. It just does not unlock the day, and the sheet tells you so before you save. This part is an honour system. Nivli believes you.

OR LET APPLE HEALTH PROVE IT
Connect Apple Health and any workout saved to it counts, whether it came from your Apple Watch or from another app. Finish a run and your apps are open before you get your phone out of your pocket. It is optional, it is read only, and Nivli writes nothing back to Health.

STREAKS THAT MEAN SOMETHING
Every day you move, the number goes up. Seven dots show the week behind you. Your longest streak is kept, and a few milestones are worth a small celebration. Nothing is shared, ranked or posted anywhere.

REST DAYS ARE PART OF TRAINING
Mark the weekdays you rest and nothing is locked on them. Your streak is not broken either. For the days that come out of nowhere there is Take today off, one tap, applied to today only.

A NUDGE, IF YOU WANT ONE
Pick an evening time and Nivli reminds you once if the day is still open. Say no and you will never hear from it.

WHAT IT CANNOT DO
Nivli shields an app when you open it. It cannot close one you already have open, and it will not pretend otherwise. It is not a parental control: it works on the iPhone it is installed on, for the person using it, and it cannot manage anyone else's device. You can clear your selection or delete the app at any moment. It is a speed bump you agreed to, not a lock someone else holds.

PRIVATE BY DESIGN
No account. No sign up. No server of ours. No analytics, no advertising, no tracking, no third party code. The apps you pick reach Nivli as opaque tokens that only iOS can resolve, so Nivli never learns their names, let alone what you do in them. Workouts read from Apple Health are read on the iPhone and never leave it. Your log, your streak and your settings live in Nivli's own storage on the phone, kept out of iCloud Backup because it can hold workouts read from Health. The only network traffic is Apple's App Store, for the subscription. App Store privacy label: Data Not Collected.

WHAT IT COSTS
One plan, $2.99 a month. There is no free tier, no ads and nothing else to buy. Restore Purchases is on the paywall and in Settings. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period, and are managed in your Apple Account settings.

Requires iOS 18 or later. iPhone only.

Nivli. Move first. Then scroll.
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://bluepenguin1234.github.io/privacy.html
```

## Keywords

```
workout,exercise,fitness,gym,run,habit,streak,blocker,block,focus,discipline,screen,unlock,move
```

Notes: 100 bytes max, comma separated, no spaces, app name not repeated. No competitor or
company names, nothing trademarked. "Screen Time" is an Apple feature name, so only the generic
word `screen` is used.

## What's New in This Version — 3.0.0

```
Nivli 3.0 is a new app.

Nivli used to be a memory for the upkeep of life. It is now something else: it locks the apps you choose until you have worked out today. If you were using the old Nivli, its features are not in this version. Everything below is new.

• Choose the apps, categories and websites that wait. Nivli shields them with Apple's Screen Time settings, on this iPhone, for you.
• Log a workout in two taps, or connect Apple Health and let a run, a lift or a class unlock the day on its own. Health is read only.
• Set the minimum length that counts, from 10 minutes to an hour.
• Your apps open until midnight. At midnight they lock again.
• Streaks, with the week behind you at a glance and your longest kept.
• Weekly rest days, and Take today off for the ones you did not plan.
• An optional evening reminder if the day is still open.
• One subscription, $2.99 a month. No free tier, no ads, nothing else to buy.
• No account, no server, no analytics. Nivli never learns which apps you picked.

Questions or ideas? suchanekbs@gmail.com
```

## Category

- Primary: **Health & Fitness**
- Secondary: **Productivity**

## URLs

- Support URL (required): `https://bluepenguin1234.github.io/support.html`
- Privacy Policy URL (required, entered under App Privacy): `https://bluepenguin1234.github.io/privacy.html`
- Marketing URL (optional): `https://bluepenguin1234.github.io/`

These are the addresses built into the app (`AppConfig.supportURL` / `privacyURL`). Host the new
`Web/index.html`, `Web/privacy.html` and `Web/support.html` at those addresses **before**
submitting; they currently serve the old product's pages.

## Age rating

App Store Connect → App Information → Age Ratings → **Set Up Age Ratings**. Answer exactly:

**In-app controls and capabilities** (first screen, tick nothing):

- Parental controls: **not selected**. Nivli uses the Screen Time API on the device's own user
  (`individual` authorization) to shield apps that same person chose. It has no family, child or
  guardian features and cannot manage another device.
- Unrestricted web access: **NO**. There is no browser, no web view and no link to arbitrary web
  content in the app.
- User-generated content: not selected. Nothing a user types leaves their phone or is visible to
  anyone else.
- Messaging / chat: not selected
- Gambling: not selected
- Loot boxes: not selected
- Advertising: not selected
- Medical / treatment information: **not selected**

**Content descriptors**: answer **None** for every one:
Cartoon or Fantasy Violence · Realistic Violence · Prolonged Graphic or Sadistic Realistic
Violence · Profanity or Crude Humor · Mature/Suggestive Themes · Horror/Fear Themes ·
**Frequent/Intense Medical/Treatment Information: NO** · Alcohol, Tobacco, or Drug Use or
References · Sexual Content or Nudity · Graphic Sexual Content and Nudity · Simulated Gambling ·
Contests.

Nivli records the length and kind of a workout so it can decide whether to unlock apps. It gives
no medical, treatment or training advice, so the medical descriptor stays at None.

**Chance-based activities**: Gambling: **No**; Loot Boxes: **No**.

**Age categories and override**: **Not Applicable** (do not choose Made for Kids; do not override
to a higher rating). Age Suitability URL: leave blank. Save.

Expected calculated rating: **4+**. The app is built for adults managing their own screen time,
and the privacy policy says so, but nothing in it warrants a higher rating.

## Copyright (required; format is year + entity, Apple adds the © symbol)

```
2026 <<OWNER: legal name>>
```

## Version and build

- Version: `3.0.0`
- Build: whatever Codemagic uploads (`100 + BUILD_NUMBER`, so it cannot collide with the old
  app's builds; the last of those was 14)

## App Review information (on the version page)

- Sign-in required: **No** (there is no login and no account)
- First name: `<<OWNER: review contact first name>>`
- Last name: `<<OWNER: review contact last name>>`
- Phone number: `<<OWNER: review contact phone>>`
- Email: `suchanekbs@gmail.com`
- Notes: paste `AppStore/REVIEW_NOTES.md` (everything below its rule)
- Attachment: none needed

## In-App Purchase display (what to set in App Store Connect)

One product is on sale. Set its English (U.S.) localization to exactly this; the app never shows
the App Store Connect description, but reviewers and the Subscriptions screen on the customer's
iPhone do. Full instructions in `AppStore/SUBSCRIPTION_SETUP.md`.

| Field | Value | Length | Limit |
|---|---|---|---|
| Product ID | `com.bluepenguin.nivli.plus.monthly` | 34 | 100 |
| Reference Name | `Nivli+ Monthly` (internal only, unchanged) | 14 | 64 |
| Display Name | `Nivli Monthly` | 13 | 30 |
| Description | `Unlock your apps by moving first` | 32 | 45 |
| Subscription group | `Nivli+` (existing, display name unchanged) | 6 | — |
| Duration | 1 month | — | — |
| Price | $2.99 (US base price) | — | — |

`com.bluepenguin.nivli.plus.yearly` and `com.bluepenguin.nivli.plus.lifetime` are removed from
sale. They stay in the account so existing customers keep their entitlement, and the app honours
them at `Restore Purchases`.

## Other version-page settings

- Platform: iOS, iPhone only (do not enable iPad; the app is portrait iPhone only)
- Minimum iOS version: 18.0
- Screenshots: see `AppStore/SCREENSHOTS.md`. **Replace every 2.x screenshot.** They show a
  different product and would fail guideline 2.3.3.
- App Preview videos: none for 3.0.0
- Content Rights: "does not contain, show, or access third-party content"
- Release: **Manually release this version**, so the new web pages can go live first
- Pricing: **Free** (the subscription is an in-app purchase; see `AppStore/SUBSCRIPTION_SETUP.md`)
- Availability: whatever the app record already has; the monthly product must be on sale in the
  same storefronts
- Export compliance: the app uses no encryption beyond what iOS provides (HTTPS to Apple's
  StoreKit only). Answer "None of the algorithms mentioned above" / exempt.
  `ITSAppUsesNonExemptEncryption = NO` is already set in the build, so App Store Connect should
  not ask.
