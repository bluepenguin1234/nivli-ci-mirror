# Screenshot plan — Nivli 3.0

Source: App Store Connect Help → Screenshot specifications (iPhone), checked September 2026.
Guideline 2.3.3: screenshots must show the app in use, no splash screens or bare title art. Text
overlays are allowed. 1 to 10 screenshots per size; JPG or PNG; no transparency (alpha); portrait
for Nivli.

**Every 2.x screenshot has to go.** They show a different product. Upload a complete new set.

**These have to come from a physical iPhone.** The Simulator has no Screen Time, so the app picker,
the shields and the lock screen over a blocked app cannot be produced there, and four of the six
shots below depend on them. Use a TestFlight build on a real phone.

## Sizes

| Slot | Required? | Accepted portrait pixel sizes | Phones that take this natively |
|---|---|---|---|
| **6.9" iPhone** | **Required** | **1320 × 2868**, 1290 × 2796, 1260 × 2736 | iPhone 16 Pro Max / 17 Pro Max / 18 Pro Max, 16 Plus (1320×2868); 15 Pro Max, 15 Plus, 14 Pro Max (1290×2796); iPhone Air (1260×2736) |
| **6.5" iPhone** | Required only if no 6.9" set is uploaded; otherwise optional (Apple scales the 6.9" set down) | **1284 × 2778**, 1242 × 2688 | iPhone 14 Plus, 13 Pro Max, 12 Pro Max (1284×2778); 11 Pro Max, XS Max (1242×2688) |
| 6.3" / 6.1" / 5.5" | Optional | 1206×2622, 1179×2556 / 1170×2532, 1125×2436, 1080×2340 / 1242×2208 | — |

Plan: upload **one set of six in the 6.9" slot** and let App Store Connect scale it everywhere
else. Add a 6.5" set only if you happen to have a phone that produces those sizes natively; the
same six shots in the same order, nothing else changes.

## The six shots (same order in App Store Connect)

| # | Screen to show | Set-up on the phone | Caption |
|---|---|---|---|
| 1 | **Home, locked.** The ring in ink with the lock, "Locked until you move", "4 apps are waiting", the streak below with the week strip | Finish onboarding with four or five apps picked, and do not log anything yet. Take it early in the day so the week strip has a few filled dots behind it | **Your apps wait until you move.** |
| 2 | **The shield.** Nivli's lock screen over a blocked app: the mark, "Move first.", "Log a workout in Nivli to unlock Safari today." (the app's name is filled in by iOS), the streak line, the mint OK button | Quit the blocked app from the App Switcher first, then tap its icon. Screenshot the shield. Pick a plain app for this (Safari is a good one) so no third-party content or logo is in the frame; the shield covers the app completely, which is the point | **Open one, and this is what you get.** |
| 3 | **Log a workout.** The sheet with the kind grid, a kind selected, 30 minutes chosen, and the line saying it counts toward today | Tap *Log a workout* on Home, pick Run and 30, screenshot before tapping *Log it* | **Log a workout in two taps.** |
| 4 | **Home, unlocked.** The ring filled mint with the check, "Unlocked for today", "42 min run · Apple Health", the streak at a decent number with the flame | Easiest with Health connected and a real workout; otherwise log one by hand and the second line reads "30 min strength · logged by you", which is just as good | **Unlocked for today. Streak plus one.** |
| 5 | **Apple Health.** The Apple Health section in Settings with the switch on, and the minimum workout picker below it set to 20 minutes | Settings → Apple Health, after allowing it. Do not screenshot Apple's own permission sheet; Apple's system UI should not be the subject of a store screenshot | **Or let Apple Health prove it.** |
| 6 | **Rest days.** The Settings screen with two or three weekdays switched on as rest days and *Take today off* below them | Settings → Rest days. Switch on Saturday and Sunday so it reads clearly at thumbnail size | **Rest days keep the streak.** |

Caption copy, exactly as it should appear if you add overlays:

```
Your apps wait until you move.
Open one, and this is what you get.
Log a workout in two taps.
Unlocked for today. Streak plus one.
Or let Apple Health prove it.
Rest days keep the streak.
```

Keep one appearance across all six. Dark is the app's default and shows the mint accent and the
night canvas at their best, so use dark unless you have a reason not to. Do not mix.

Do **not** use the paywall as a marketing screenshot. It is only needed as the *review* screenshot
for the subscription (see `AppStore/SUBSCRIPTION_SETUP.md`), and a price is not a feature.

## Capturing from a TestFlight build on an iPhone (no Mac needed)

1. Install **TestFlight** from the App Store, open the invitation link or code, tap **Install**
   for Nivli.
2. Tidy the phone: **Settings → Focus → Do Not Disturb** on (hides incoming banners), battery
   above 50 % and Low Power Mode off (no yellow battery), Wi-Fi or cellular on, no Personal
   Hotspot and no screen recording running (both add coloured status-bar pills). The exact clock
   time does not matter; Apple does not require 9:41.
3. Set the app up: allow Screen Time, pick four or five apps in the picker, allow Apple Health if
   you can, subscribe with a sandbox account, set a couple of rest days.
4. Get the state you want before each shot. Shots 1 and 2 need the day **not** done; shot 4 needs
   it done. Do 1, 2 and 3 first, then log the workout and do 4, 5 and 6.
5. Take each screenshot: **Side button + Volume Up** together. The thumbnail appears bottom left;
   leave it, it saves to Photos automatically.
6. Check the size: in **Photos**, open the screenshot and swipe up (or tap ⓘ). The resolution must
   match one of the accepted sizes in the table.
7. Shot 2 (the shield): quit the app you are about to open from the App Switcher first. A shield
   stops an app being opened; it does not close one that is already running, so a backgrounded app
   will resume without it.

### If your phone is not a Pro Max or Plus

A 6.3" or 6.1" phone (iPhone 15/16/17, Pro, e, 13/14) produces screenshots Apple will not accept
in the required 6.9" slot. Upscale them once with the built-in **Shortcuts** app:

1. **Shortcuts → + (new shortcut) → Add Action**.
2. Add **Select Photos** (turn on *Select Multiple*).
3. Add **Resize Image** and set **Width** and **Height** exactly:
   - from 1206 × 2622 (iPhone 16 Pro / 17 Pro): to **1320 × 2868**
   - from 1179 × 2556 or 1170 × 2532 (iPhone 15/16/17, 16e, 13/14): to **1290 × 2796**
   (both are the same 19.5:9 shape, so nothing looks stretched)
4. Add **Save to Photo Album** → Done. Run the shortcut and pick the six screenshots.
5. Check the new files show the exact resolution in Photos before uploading.

An iPhone 11 or XR gives 828 × 1792, which is not accepted anywhere; upscale to 1284 × 2778 (the
6.5" slot) the same way, or borrow a newer phone.

### Uploading from the iPhone

1. In Safari open https://appstoreconnect.apple.com → **Apps → Nivli → 3.0.0 Prepare for
   Submission**. If the page is cramped, tap **ᴬA → Request Desktop Website**.
2. Under **App Previews and Screenshots → iPhone 6.9" Display**, delete the old 2.x set first,
   then tap **Choose File** → **Photo Library** → select the six in order → upload.
3. Drag to reorder if needed, then **Save** at the top right.
4. Leave the 6.5" section empty unless you have native 6.5" shots, in which case replace that set
   too.

### Adding the captions (optional)

Raw screenshots are perfectly acceptable. If you want the caption above each image, use a free
template tool on the phone such as **Canva** (search "App Store screenshot 6.9"), place each
screenshot, set the caption in the system font (SF Pro or Helvetica), use ink `#142B39` as the
background with white text and mint `#5EDCC0` for the accent, and export as PNG at exactly
1320 × 2868. Check the size in Photos before uploading. Use the caption copy in the block above,
word for word, so the store page and the app agree.

## Also needed on the store page

- App icon: supplied inside the build (1024 × 1024, no transparency). Nothing to upload separately.
- App Preview video: none for 3.0.0.
