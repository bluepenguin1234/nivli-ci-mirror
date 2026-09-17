# Release notes

Paste the block below into App Store Connect → version **3.0.0** → **What's New in This Version**
(max 4,000 characters, plain text, line breaks only). Use the same text for TestFlight's "What to
Test". It is the same text as the *What's New* section of `AppStore/LISTING.md`; if you edit one,
edit both.

Nivli 3.0 replaces a different product under the same App Store record, so this field has more
work to do than usual: someone who already has Nivli installed will be updated into an app that
does something else. Say so in the first line.

## 3.0.0 — September 2026

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

## Template for future versions

Rules: lead with what the customer gets, not what changed in code. Bullets, present tense, no
jargon, no "bug fixes and performance improvements" on its own line; say which bug. Keep it under
twelve lines, because people read the first two. Never mention a feature that is not in the build.
Update the version number in App Store Connect and in the build before pasting.

```
Nivli X.Y

New
• <one line: what you can now do, e.g. "Pick a different minimum for weekends">

Improved
• <one line: what got faster, clearer or easier>

Fixed
• <one line: the symptom in plain words, e.g. "A workout finished just before midnight now counts for that day">

Questions or ideas? suchanekbs@gmail.com
```

Patch releases (X.Y.1) may use a single line, for example
`Fixes apps staying locked after a workout imported from Apple Health.`
