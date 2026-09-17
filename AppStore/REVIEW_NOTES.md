# App Review notes

Paste everything below the rule into App Store Connect → App Review Information → Notes.
Preflight check 5 fails if this whole file passes 4,000 bytes; keep it under 3,500 so there is
room to answer a reviewer's follow-up. Anything added has to be paid for by a trim.

---

Nivli locks the apps the user chooses until they have logged a workout that day. Version 3.0 replaces a completely different product (a memory app) under the same record. No account, no login, no server of ours.

PLEASE TEST ON A PHYSICAL IPHONE
The Simulator has no Screen Time, so authorization fails there and nothing can be shielded. On a device, iOS 18 or later, everything below works.

SCREEN TIME (FAMILY CONTROLS)
Requested on the fifth onboarding page with AuthorizationCenter.requestAuthorization(for: .individual): the device's own user, on their own iPhone. No parental, family or child features; Nivli cannot manage another device. It is used for one thing, shielding the apps, categories and websites the user picks in Apple's FamilyActivityPicker. The selection arrives as opaque tokens, so Nivli never learns which apps they are, and nothing about the selection or app use is reported anywhere. A DeviceActivityMonitor extension re-applies the shield at midnight. Shields are cleared when the subscription is not valid, onboarding is unfinished, the selection is empty, it is a rest day, or the day's workout is done, and iOS removes them if the app is deleted.

THE FLOW TO TEST
1. Launch. Onboarding, eight pages.
2. Page 5: tap Allow Screen Time, approve the system prompt, tap Choose apps, pick one or two you can open easily (Safari or Messages is fine), close the picker.
3. Page 6: Apple Health is optional. Skip it or allow it; either way continue.
4. Page 7: reminders, optional.
5. Paywall: Start for $2.99/month with a sandbox account, or Restore Purchases.
6. Home appears, showing the apps are locked.
7. Press Home, open one of the apps you picked. iOS shows the Nivli shield ("Move first."). Tap OK.
8. Back in Nivli, tap Log a workout, pick any kind, pick 30 minutes, tap Log it.
9. Open the same app again. It opens normally. It stays open until midnight.

Note: a shield stops an app being opened. It cannot close one already running, so quit the app before step 7.

SUBSCRIPTION (sandbox), group "Nivli+"
One plan on sale: com.bluepenguin.nivli.plus.monthly, auto-renewable, 1 month, USD 2.99. Hard paywall after onboarding; there is no free tier. Restore Purchases, price from StoreKit, renewal terms, Apple's standard EULA and the privacy policy are all on the paywall. com.bluepenguin.nivli.plus.yearly and .lifetime were sold by the previous app, are no longer offered, and are still honoured as valid entitlements on restore. Family Sharing is off.

APPLE HEALTH
Optional and read-only: workouts only, nothing else requested, nothing ever written to Health. A workout at or over the user's minimum (default 20 minutes) unlocks the day, with background delivery so a watch workout unlocks without opening the app. Refuse it and logging by hand does the same job.

NOTIFICATIONS
Optional, asked once in onboarding. Local only: apps unlocked, and an evening nudge. Refuse and nothing else changes.

PRIVACY
No account, no server, no analytics, no advertising, no third-party SDKs. The only network traffic is StoreKit. Everything else is on the device in the App Group. App Privacy: "Data Not Collected".

Contact: suchanekbs@gmail.com
