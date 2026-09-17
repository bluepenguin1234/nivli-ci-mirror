# The subscription — what to change in App Store Connect for Nivli 3.0

For the owner. Nothing here needs Xcode or a Mac. Do all of it in a desktop browser at
https://appstoreconnect.apple.com (it works on iPhone Safari too, but it is easier on a big
screen). Sources: App Store Connect Help: "Offer auto-renewable subscriptions", "In-App Purchase
information", "Set a subscription's availability", "Set up introductory offers"; App Store Review
Guidelines 3.1.1 and 3.1.2.

**Nothing has to be created.** All three products already exist from the previous Nivli, in the
subscription group **Nivli+**. Product IDs can never be changed or reused, and the app is built
against these exact strings, so leave them alone.

| Product | Type | Product ID | Price | In 3.0 |
|---|---|---|---|---|
| Nivli+ Monthly | Auto-renewable, 1 month | `com.bluepenguin.nivli.plus.monthly` | $2.99 | **The only plan on sale** |
| Nivli+ Yearly | Auto-renewable, 1 year | `com.bluepenguin.nivli.plus.yearly` | $19.99 | Remove from sale, still honoured |
| Nivli+ Lifetime | Non-consumable | `com.bluepenguin.nivli.plus.lifetime` | $39.99 | Remove from sale, still honoured |

"Still honoured" means the app treats an existing yearly or lifetime purchase as a valid
subscription when the customer taps Restore Purchases. Nobody loses what they paid for. Removing
a product from sale stops new purchases; it does not cancel or refund existing ones, and an
active yearly subscription keeps renewing until its owner cancels it.

Field limits, for reference: reference name 64 chars · display name 2–30 chars · description max
45 chars · review notes max 4,000 chars.

---

## 0. Check the agreement first

**Business → Agreements, Tax, and Banking**: the **Paid Apps** agreement must show **Active**. If
it lapsed (Apple updates the terms and the Account Holder has to accept the new version), in-app
purchases will not load in the app, in TestFlight or in review, and the paywall will show its
error state. Fix this before anything else.

## 1. Rename the monthly subscription

1. **Apps → Nivli → Monetization → Subscriptions → Nivli+ → Nivli+ Monthly**.
2. Leave **Reference Name** as `Nivli+ Monthly`. It is internal, nobody sees it, and changing it
   only makes your own reports harder to read.
3. Under **App Store Localizations**, click **English (U.S.)** (or the pencil next to it) and set:
   - **Display Name**: `Nivli Monthly`
   - **Description**: `Unlock your apps by moving first`
4. **Save**.

That display name and description are what the customer sees in **Settings → [their name] →
Subscriptions** on their iPhone, and what App Review reads. The app itself never shows the App
Store Connect description; the paywall writes its own copy and takes only the price from StoreKit.

The old text ("Nivli+ Monthly" / "Reminders, custom repeats, export, household") describes a
product that no longer exists and must not be left in place.

## 2. Check the price is still $2.99

On the same page, **Subscription Prices**. The current US price should read **USD 2.99**. If it
does, change nothing.

If it does not, click the price → **Edit** (or **+ Add Subscription Price**) → United States →
2.99 → **Next**, keep Apple's automatic conversions for the other storefronts → **Confirm**. A
price change takes effect for new customers straight away; existing subscribers are handled by
Apple's own rules and, for an increase, have to consent. Avoid changing it if you do not need to.

Do not touch **Subscription Duration** (1 month). It cannot be changed after review.

## 3. Remove the yearly subscription from sale

1. **Monetization → Subscriptions → Nivli+ → Nivli+ Yearly**.
2. Find the **Availability** box → **Edit**.
3. Choose **Remove from Sale** (on some account layouts: deselect every country and region, which
   is the same thing).
4. **Save**. The product's status changes to *Removed from Sale* or *Developer Removed from Sale*.

Nobody can buy it any more. Anyone who already has it keeps it, keeps renewing, and Nivli keeps
letting them in.

## 4. Remove the lifetime purchase from sale

The non-consumable lives on a different screen.

1. **Monetization → In-App Purchases → Nivli+ Lifetime**.
2. Open **Pricing and Availability** (some layouts call the box **Availability**).
3. Uncheck **all** countries and regions, or use **Remove from Sale** if your layout offers it.
4. **Save**.

## 5. Review screenshot and review notes on the monthly product

Apple needs one screenshot per product that is being submitted, showing the purchase inside the
app. Reviewers see it; customers never do.

1. Back on **Nivli+ Monthly**, find **Review Information**.
2. **Screenshot**: upload a plain iPhone screenshot of Nivli's **paywall** from the TestFlight
   build. Any accepted iPhone screenshot size works (1320 × 2868 from a Pro Max is ideal); JPG or
   PNG, no transparency. How to capture it: `AppStore/SCREENSHOTS.md`.
3. **Review Notes**: paste

   `Nivli's only plan. The paywall appears at the end of onboarding and there is no free tier. Subscribing lets Nivli shield the apps the user picked until they log a workout that day. Price, renewal terms, Restore Purchases, Apple's standard EULA and the privacy policy are all on the paywall. Test on a physical iPhone; the Simulator has no Screen Time.`

4. **Save**. The status should read **Ready to Submit**. If it says **Missing Metadata**,
   something above is empty, usually the screenshot or the localization.
5. **Family Sharing**: leave it **off**. Apple does not let you turn it off again once it is on.

## 6. Attach it to the 3.0.0 submission

The monthly product was already approved with the previous app, so it does not have to travel with
this version. Attach it anyway, because its localization changed:

1. **iOS App → 3.0.0 Prepare for Submission**.
2. Scroll to **In-App Purchases and Subscriptions** → **+** → tick **Nivli+ Monthly** → **Done**.
3. **Save**.

If the section does not appear, the product is not **Ready to Submit**; go back to step 5.

## 7. Test it before submitting

1. **Users and Access → Sandbox → Test Accounts → +**: create a sandbox Apple Account (any unused
   email address; it does not have to receive mail).
2. On the iPhone: **Settings → App Store → Sandbox Account**, near the bottom, and sign in with
   it. The row appears once a TestFlight build is installed.
3. In the TestFlight build, go through onboarding to the paywall and buy the monthly plan. No real
   charge. Then delete and reinstall the app and tap **Restore Purchases** to check it comes back.
4. Sandbox subscriptions renew fast (a one-month subscription renews every five minutes, up to six
   times), so you can watch it expire too. When it expires, Nivli should stop shielding anything
   and show the paywall again.
5. Check that the yearly and lifetime products no longer appear anywhere in the app. They should
   not; the paywall asks StoreKit for the monthly product only.
6. Product changes can take up to an hour to show in sandbox.

---

## Adding a free trial later (optional)

You do not need one to ship. If you want to try a **7-day free trial** afterwards, it is an
**introductory offer**, and the app picks it up on its own: the paywall reads the offer from
StoreKit and writes the trial into its own button and renewal text. No new build, no code change.

1. **Monetization → Subscriptions → Nivli+ → Nivli+ Monthly → Introductory Offers** (or
   **Subscription Prices → View all Subscription Pricing → Introductory Offer**).
2. **Set Up Introductory Offer** (or **+**).
3. **Countries or Regions**: all of them, unless you want to test one market first.
4. **Start Date**: today or a date you choose. **End Date**: leave as *No End Date* so it keeps
   running.
5. **Type of Introductory Offer**: **Free**.
6. **Duration**: **1 week** (Apple offers 3 days, 1 week, 2 weeks, 1 month, 2 months, 3 months,
   6 months, 1 year; there is no "7 days" entry, and 1 week is the same thing).
7. **Confirm**, then **Save**.

Things worth knowing before you do it:

- Each customer gets one introductory offer per subscription group, ever. Anyone who has already
  subscribed to Nivli+ in the past, on any of the three products, is not eligible, and Nivli's
  paywall will simply show the normal price for them. That is StoreKit's decision, not a bug.
- An introductory offer does not need a new app review, but it can take a few hours to appear.
- Guideline 3.1.2 requires the trial length, the price after it and the renewal terms to be on the
  paywall. The app composes that sentence from the StoreKit offer automatically; read it once on
  the device after the offer goes live and check it matches what you set here.
- Test it with a **fresh** sandbox account. A sandbox account that has already bought Nivli+ is
  no longer eligible and will show the plain price.

## Mandatory links (guideline 3.1.2 and Schedule 2 of the Developer Program License Agreement)

Already in the app, on the paywall, under the buy button. Keep them working:

- **Terms of Use (EULA)**: Apple's standard EULA,
  `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`. It is also at the end of
  the App Store description (see `LISTING.md`). Do not upload a custom EULA; the standard one
  applies by default.
- **Privacy Policy**: `https://bluepenguin1234.github.io/privacy.html`, also entered under
  **App Privacy**.

Prices in the app come from StoreKit, so every customer sees their own currency. The figures in
this file are the US base prices, and no price is hard-coded anywhere in the app.

## What the plan must promise, and nothing more

The subscription unlocks the whole app: shielding the apps, categories and websites the user
picks; Apple Health unlocking the day; streaks, rest days and the evening reminder. There is no
free tier and no second plan, so there is nothing to compare it against and nothing to hold back.
Do not add "coming soon" features to the product description or the paywall.
