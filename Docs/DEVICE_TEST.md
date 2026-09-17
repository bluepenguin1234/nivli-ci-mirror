# Device test, on a real iPhone

For the owner. Do this on the exact TestFlight build you intend to submit, on a real iPhone
running iOS 18 or later. The Simulator has no Screen Time, so most of this cannot be tested
anywhere else.

It takes about 30 minutes, plus one overnight wait for step 34. Tick every line. If an
"Expected" line does not match what you see, stop, note the step number, and send it to your
engineering session with what happened instead.

**Before you start**

- [ ] 1. Install **TestFlight** from the App Store, open the invitation, and install Nivli.
  **Expected:** Nivli's icon on the Home Screen with the orange TestFlight dot next to it.
- [ ] 2. Create a sandbox tester: App Store Connect, **Users and Access**, **Sandbox**,
  **Test Accounts**, **+**. Any unused email address works and it never has to receive mail.
  **Expected:** the account is listed.
- [ ] 3. On the iPhone, **Settings**, **App Store**, scroll to the bottom, **Sandbox
  Account**, sign in with it. The row only appears once a TestFlight build is installed.
  **Expected:** the sandbox email shows under Sandbox Account.
- [ ] 4. Pick two apps you can open easily and are happy to have locked for an evening.
  Safari and Messages are good choices. Quit both from the App Switcher.
  **Expected:** nothing on screen; this is just preparation.

## Fresh install walkthrough

- [ ] 5. Open Nivli. **Expected:** the "Ni" mark breathing slowly on a dark background,
  "Move first. Then scroll.", and a **Get started** button. No progress bar yet.
- [ ] 6. Tap **Get started**. **Expected:** "What are you here for?" with five rows, a thin
  progress bar and a back arrow at the top, and **Continue** greyed out.
- [ ] 7. Tap two of the rows, then **Continue**. **Expected:** each tapped row shows a tick,
  Continue turns solid, and the next page is "How often do you move now?".
- [ ] 8. Choose one answer, **Continue**. **Expected:** "How much of your day goes to your
  phone?".
- [ ] 9. Choose **2 hours**. **Expected:** a card slides up reading "≈ 30 days" and "of your
  year, on your phone". Choosing "I'd rather not know" would show no card.
- [ ] 10. **Continue**. **Expected:** "Choose the apps that wait", with a card offering
  **Allow Screen Time**.
- [ ] 11. Tap **Allow Screen Time**. **Expected:** an Apple system sheet asking for Screen
  Time access for Nivli, with a button to allow and a button to refuse. The exact wording
  changes between iOS versions. Tap the one that allows it. If Face ID or your Screen Time
  passcode is requested, that is iOS, not Nivli.
- [ ] 12. **Expected:** back in Nivli, the card now says "Pick the apps, categories or sites
  that should wait" with a **Choose apps** button.
- [ ] 13. Tap **Choose apps**, pick the two apps from step 4, close the picker.
  **Expected:** a green chip reading something like "2 apps", the button now reads **Change
  apps**, and **Continue** is enabled.
- [ ] 14. **Continue**. **Expected:** "How will Nivli know you moved?" with an Apple Health
  card and a row of minute choices with **20** selected.
- [ ] 15. Tap **Connect Apple Health**. **Expected:** Apple's Health permission sheet, asking
  to read **Workouts** and nothing else. There is no "write" section, because Nivli never
  writes to Health. Turn the Workouts switch on and tap Allow.
- [ ] 16. **Expected:** back in Nivli, the card shows a **Connected** chip and the Connect
  button is gone.
- [ ] 17. Leave the minimum at **20** and tap **Continue**. **Expected:** "Stay on track"
  with a time picker showing 6:00 pm, a **Turn on reminders** button and a quieter **Not
  now** under it.
- [ ] 18. Tap **Turn on reminders**. **Expected:** the iOS prompt, roughly "Nivli Would Like
  to Send You Notifications", with Don't Allow and Allow. Tap **Allow**.
- [ ] 19. **Expected:** the summary page, "Your first streak starts today", with a card
  reading back your apps, "≥ 20 min", Apple Health **On**, and Reminder **6:00 PM**. Seven
  dots underneath with the last one lit.
- [ ] 20. Tap **Continue**. **Expected:** the paywall. The mark, "Unlock your apps by moving
  first", three benefit rows, and a card reading **Nivli** and **$2.99 / month**. If it shows
  a spinner for more than a few seconds, or a "The App Store didn't answer" message, the
  Paid Apps agreement or the sandbox sign-in is the usual cause.
- [ ] 21. Tap **Start for $2.99 / month**. **Expected:** Apple's purchase sheet with the word
  **Sandbox** or **[Environment: Sandbox]** somewhere on it, so you know no real money is
  involved. Confirm it, and sign in with the sandbox account if asked.
- [ ] 22. **Expected:** a short success, then Home. The ring is empty with a padlock,
  "Locked until you move", "2 apps are waiting". The streak card reads 0 and Longest 0. The
  "Apps that wait" card lists your two apps by name and icon, drawn by iOS.

## The lock and unlock cycle

- [ ] 23. Press Home, make sure one of your chosen apps is **not** in the App Switcher, then
  tap its icon. **Expected:** Nivli's shield instead of the app. Dark background, the mark,
  **Move first.**, and "Log a workout in Nivli to unlock Safari today." A single mint **OK**
  button. Tap OK.
  *If the app opens normally, it was already running in the background. Quit it from the App
  Switcher and try again. A shield stops an app being opened; it cannot close one that is
  already open.*
- [ ] 24. Back in Nivli, tap **Log a workout**, choose **Run**, tap the **10** chip.
  **Expected:** the line under the duration reads "Under your 20-minute minimum. It's saved,
  but your apps stay locked."
- [ ] 25. Tap the **30** chip. **Expected:** the line changes to a green "Counts toward
  today".
- [ ] 26. Tap **Log it**. **Expected:** a haptic, the sheet closes, and a full-screen
  celebration: a tick, "Unlocked." and "1-day streak". It clears itself after about two
  seconds, or on a tap.
- [ ] 27. **Expected on Home:** the ring is filled mint with a tick, "Unlocked for today",
  "30 min run · logged by you". The streak reads 1, today's dot is a filled tick, and the
  big button has become a quiet **Add another**.
- [ ] 28. Open the same app again. **Expected:** it opens normally, with no shield.
- [ ] 29. Open Nivli, **Settings**, check the **Subscription** section. **Expected:**
  "Active · renews" with a date. In sandbox the date is minutes away, not a month, because
  sandbox subscriptions run fast.

## Rest days

- [ ] 30. Settings, **Rest days**, switch on **today's weekday**. **Expected:** the switch
  stays on, and going back to Home shows the ring filled mint with a **leaf**, "Rest day",
  "Nothing is locked today".
- [ ] 31. Open one of your chosen apps. **Expected:** it opens normally. Nothing is locked on
  a rest day.
- [ ] 32. Switch that weekday back off in Settings. **Expected:** Home goes back to
  "Unlocked for today" (because you logged a workout in step 26), not to locked.

## Take today off

- [ ] 33. Settings, **Rest days**, tap **Take today off**. **Expected:** a confirmation
  saying "Nothing is locked until tomorrow. Your streak is kept." Confirm it. The button now
  reads "Today is a rest day" and is greyed out, and Home shows the leaf and "Rest day".
  There is no undo, so the day stays a rest day until tomorrow. If you would rather keep
  testing today's locking, undo this by toggling the weekday switch instead and skip this
  step until the end.

## Midnight re-lock

This is the one thing that needs patience.

- [ ] 34. **Do not change the iPhone's date or time to test this.** Moving the clock forward
  does not make iOS fire a DeviceActivity schedule, and it does confuse Screen Time,
  StoreKit sandbox expiry and your own reading of the result. It will make the test lie to
  you.
  **Expected:** nothing; this is an instruction, not a check.
- [ ] 35. Finish today with the day unlocked (log a 30 minute workout if it is not), make
  sure today is **not** a rest day, and leave the phone overnight. The next morning, before
  opening Nivli, open one of your chosen apps.
  **Expected:** the **Move first.** shield, without Nivli having been opened. The shield's
  second line should read "Streak: 1 day. Keep it." or higher.
- [ ] 36. Then open Nivli. **Expected:** the ring is empty with the padlock, "Locked until
  you move", and yesterday's dot on the week strip is a filled tick while today's is a mint
  outline.
  *If step 35 shows the app opening normally but step 36 shows Nivli locked, the midnight
  extension did not run but the app corrected itself on foreground. Report it: the app is
  still usable, but the re-lock is the point.*

## Apple Health background unlock

Needs an Apple Watch, or the Fitness app, or any app that writes workouts to Health.

- [ ] 37. Make sure today is locked (no workout logged yet, not a rest day). Confirm it by
  seeing the shield on one of your apps.
  **Expected:** the shield.
- [ ] 38. Record a workout of at least 20 minutes that ends up in Health. On an Apple Watch,
  start any workout and end it after 20 minutes. Without a Watch, open **Fitness** or
  another app that saves workouts to Health and record one. **Do not open Nivli.**
  **Expected:** within a minute or two of the workout being saved, a notification headed
  **Apps unlocked**, with a body like "Workout detected. Streak: 2 days."
- [ ] 39. Without opening Nivli, open one of your chosen apps. **Expected:** it opens
  normally.
- [ ] 40. Now open Nivli. **Expected:** "Unlocked for today" and a line naming the workout
  and **Apple Health**, for example "22 min run · Apple Health".
  *If the notification does not arrive but the app shows the workout when you open it, the
  import works and the background delivery did not. Report it with the timing.*

## Subscription lapse

Sandbox subscriptions renew every few minutes and stop after six renewals, so a lapse can be
watched in about half an hour. You can also force it.

- [ ] 41. **Settings** (the iOS one), **App Store**, **Sandbox Account**, **Manage**, find
  Nivli, and cancel the subscription. On some iOS versions this is under **Manage
  Subscriptions** on the same screen.
  **Expected:** the sandbox subscription shows as cancelled or expiring.
- [ ] 42. Wait for it to expire, then open Nivli. **Expected:** Home shows the ring empty
  with an **open** padlock, "Subscription ended", "Your apps are not locked", and a card
  reading "Your subscription ended" with **Start again** and **Restore Purchases**.
- [ ] 43. Open one of your chosen apps. **Expected:** it opens normally. Nothing is shielded
  while the subscription is not valid. This is deliberate.
- [ ] 44. Tap **Start again** and buy it again with the sandbox account. **Expected:** the
  paywall closes, and Home is locked or unlocked according to whether today's workout is
  done. Your streak and your app selection are exactly as they were.
- [ ] 45. Delete the app, reinstall it from TestFlight, and walk through onboarding to the
  paywall. **Expected:** because the sandbox account still holds the subscription, the
  paywall should pass straight through to Home on its own, without showing a price. If it
  does stop on the paywall, tap **Restore Purchases**, which must finish onboarding without
  charging anything. Either outcome is a pass; a paywall that cannot be got past is not.
  *Note that a reinstall starts onboarding from the beginning, because deleting the app
  removes its storage. That is expected.*

## Deleting the app removes the shields

- [ ] 46. With a locked day and shields on, confirm the shield appears on one of your chosen
  apps, then delete Nivli from the Home Screen (press and hold, **Remove App**, **Delete
  App**).
  **Expected:** the shield is gone and the app opens normally. iOS removes the shields on
  its own; Nivli does not have to do anything.
- [ ] 47. Reinstall from TestFlight and restore the purchase as in step 45, so the remaining
  checks have something to look at.
  **Expected:** Home, with an empty streak and no apps selected until you pick them again.

## Appearance, text size and VoiceOver

- [ ] 48. Settings inside Nivli, **Appearance**, **Light**. **Expected:** every screen turns
  to a pale canvas with white cards and a deeper teal accent. No pure white and no system
  grey. Check Home, the log sheet and Settings.
- [ ] 49. Set it back to **Dark**, then try **Match iPhone** and flip the iPhone's own
  appearance in iOS Settings, Display and Brightness. **Expected:** Nivli follows it.
- [ ] 50. iOS **Settings**, **Accessibility**, **Display and Text Size**, **Larger Text**,
  switch on Larger Accessibility Sizes and drag the slider to about three-quarters.
  **Expected:** back in Nivli, every screen still works. Text wraps onto more lines instead
  of being cut off, buttons grow, and nothing important is pushed off the bottom of the
  screen without the screen scrolling. Check Home, the log sheet, the summary page and
  Settings.
- [ ] 51. iOS **Settings**, **Accessibility**, **Motion**, **Reduce Motion** on. **Expected:**
  in Nivli the mark stops breathing, pages cross-fade instead of sliding, and the celebration
  appears without confetti.
- [ ] 52. Turn Reduce Motion back off. iOS **Settings**, **Accessibility**, **VoiceOver** on
  (or triple-click the side button if you set that shortcut up). Swipe right through Home.
  **Expected, roughly in this order:** the ring reads as one item, for example "Locked until
  you move, 2 apps are waiting"; the streak card reads "Streak, 3 days. Longest 5."; the week
  strip reads "Last seven days, 3 of 7 days done"; the button reads "Log a workout"; the gear
  reads "Settings". Nothing reads as an unlabelled button or an image.
- [ ] 53. With VoiceOver still on, open the log sheet and swipe through it. **Expected:**
  each kind tile reads its name ("Run", "Strength") and says it is selected when it is; each
  duration chip reads "30 minutes"; **Log it** is reachable.
- [ ] 54. Log a workout with VoiceOver on. **Expected:** the celebration reads as one item,
  something like "Unlocked. 1 day streak. Tap to dismiss.", and dismissing it works.
- [ ] 55. Turn VoiceOver and Larger Text back off.
  **Expected:** everything back to normal.

## When you are done

- [ ] 56. Take the six App Store screenshots while the app is still set up. The order, the
  state each one needs and how to capture them is in `AppStore/SCREENSHOTS.md`.
  **Expected:** six screenshots at an accepted size, checked in Photos.
- [ ] 57. Take one extra screenshot of the **paywall**. It is required as the review
  screenshot on the subscription product (`AppStore/SUBSCRIPTION_SETUP.md`, step 5).
  **Expected:** a clean shot of the paywall with the price visible.
- [ ] 58. Sign out of the sandbox account if you want your own App Store account back:
  iOS **Settings**, **App Store**, **Sandbox Account**, sign out.
  **Expected:** the row is empty again.
