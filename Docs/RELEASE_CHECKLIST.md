# Release checklist, from this repository to "Submit for Review"

Do these in order. Steps marked **(owner)** need your Apple, Codemagic or GitHub accounts;
everything else is already done in the repository. Nothing here needs a Mac.

Two steps have a wait attached that nobody controls: Apple's Family Controls approval
(section B, days to weeks) and App Review itself. Start B on day one, whatever else is
unfinished.

## A. A green build

1. **(owner)** Connect Codemagic to the repository. `Docs/CODEMAGIC.md` section 1 has the
   clicks: codemagic.io, sign in with GitHub, **Add application**, `bluepenguin1234/nivli`,
   project type **Codemagic YAML**.
2. **(owner)** **Start new build**, branch `main`, workflow **iOS Compile — Fast check**.
   About 8 minutes, and it needs no Apple credentials at all.
3. If it is red: open the build, expand the red step, and copy the first line containing
   `error:` together with the file name next to it into your engineering session. Push the
   fix, re-run. Expect one or two rounds; the code has never been compiled on Apple's
   toolchain. Warnings can be ignored.
4. **(owner)** When the compile is green, run **iOS Unit — Build + unit tests**, about 15
   minutes. Green means every rule about streaks, rest days, shields and entitlements passes
   on Apple's own toolchain.
5. Optional: **iOS Verify — Build + all tests** adds the launch UI test, about 25 minutes.
   Nothing later depends on it.

## B. Family Controls, the long pole

6. **(owner)** Submit the distribution request at
   https://developer.apple.com/contact/request/family-controls-distribution, signed in with
   the Account Holder Apple Account. `Docs/HANDOFF.md` step 2 has the exact paragraph to
   paste. Name all three bundle IDs in it: `com.bluepenguin.nivli`,
   `com.bluepenguin.nivli.monitor`, `com.bluepenguin.nivli.shield`.
7. **(owner)** Wait for Apple's email. Development builds get the entitlement automatically,
   but **TestFlight and App Store builds only get it after this approval**, and a signed
   build without it fails at the signing step with "entitlement not supported". If Apple asks
   follow-up questions, answer from `AppStore/REVIEW_NOTES.md`.
8. **(owner)** After approval, check that **Family Controls (Distribution)** now appears in
   the capability list of the App IDs in the developer portal. If it does not, the request
   was approved for a different app record.

## C. Developer portal capabilities

Codemagic creates App IDs on the first signed build, but it never switches capabilities on.
`Docs/CODEMAGIC.md` section 2b has the click-by-click version.

9. **(owner)** developer.apple.com, **Certificates, Identifiers & Profiles**,
   **Identifiers**, open **com.bluepenguin.nivli**. Tick **App Groups** (configure it to
   `group.com.bluepenguin.nivli`), **HealthKit**, and **Family Controls (Distribution)**.
   Untick **iCloud** and **Push Notifications**; 3.0 uses neither. Save, Confirm.
10. **(owner)** Register **com.bluepenguin.nivli.monitor** as a new explicit App ID,
    description "Nivli Monitor", with **App Groups** (same group) and **Family Controls
    (Distribution)**.
11. **(owner)** Repeat for **com.bluepenguin.nivli.shield**, description "Nivli Shield".
12. The old `…nivli.widgets` and `…nivli.share` App IDs can stay. Nothing uses them.

## D. App Store Connect, money and the subscription

Full instructions: `AppStore/SUBSCRIPTION_SETUP.md`.

13. **(owner)** **Business**, **Agreements, Tax, and Banking**: the **Paid Apps** agreement
    must read **Active**. If Apple has updated its terms, the Account Holder has to accept
    the new version. Until this is right, in-app purchases do not load in the app, in
    TestFlight or in review, and the paywall shows its error state. Fix this before anything
    else in this section.
14. **(owner)** **Nivli**, **Monetization**, **Subscriptions**, group **Nivli+**, **Nivli+
    Monthly**. Under App Store Localizations set Display Name **Nivli Monthly** and
    Description **Unlock your apps by moving first**. Leave the reference name alone.
15. **(owner)** On the same page, confirm the price is still **USD 2.99** and the duration
    is **1 month**. Duration cannot be changed after review, so do not touch it.
16. **(owner)** **Nivli+ Yearly**: Availability, **Remove from Sale**. It keeps renewing for
    anyone who already has it, and the app still honours it.
17. **(owner)** **Monetization**, **In-App Purchases**, **Nivli+ Lifetime**: same thing on
    its Pricing and Availability screen. Removing from sale never cancels or refunds an
    existing purchase.
18. **(owner)** Still on **Nivli+ Monthly**, fill in **Review Information**: the review
    screenshot of the paywall (you take it in section G) and the review note from
    `AppStore/SUBSCRIPTION_SETUP.md` step 5. Leave **Family Sharing** off; it cannot be
    turned off again once on. The product should read **Ready to Submit**.

## E. Codemagic credentials

19. **(owner)** If the `appstore_credentials` variable group from the previous Nivli is
    still in Codemagic, skip to section F. Otherwise follow `Docs/CODEMAGIC.md` sections 3
    and 4 and add four secure variables: `APP_STORE_CONNECT_PRIVATE_KEY` (the whole `.p8`
    file, BEGIN to END), `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`
    and `CERTIFICATE_PRIVATE_KEY`. Never paste any of them into GitHub or a chat.

## F. TestFlight

20. **(owner)** Codemagic, **Start new build**, workflow **iOS Release — Sign + TestFlight**.
    About 20 minutes. It runs preflight and the unit tests first, then signs all three
    bundles and uploads. Build numbers are `100 + Codemagic's counter`, so they can never
    collide with the previous app's builds.
21. **(owner)** App Store Connect, **TestFlight**. Apple processes the build for 5 to 30
    minutes. Add yourself as an internal tester, then install Nivli through the **TestFlight**
    app on your iPhone.
22. **(owner)** Create a sandbox test account (**Users and Access**, **Sandbox**, **Test
    Accounts**) and sign into it on the iPhone under **Settings**, **App Store**, **Sandbox
    Account**.

## G. The device test

23. **(owner)** Work through `Docs/DEVICE_TEST.md` from top to bottom on the build you
    intend to submit. It takes about 30 minutes plus one overnight wait.
24. **(owner)** The three checks that matter most: a chosen app shows the "Move first."
    shield; logging a 30-minute workout opens it; the next morning it is locked again without
    Nivli having been opened.
25. **(owner)** Anything that does not match an "Expected" line goes to your engineering
    session with the step number. A fix means a new build, which means repeating section F.
26. **(owner)** While the app is set up, take the six App Store screenshots per
    `AppStore/SCREENSHOTS.md`, plus one of the paywall for step 18.

## H. Publish the web pages

The app links to `https://bluepenguin1234.github.io/privacy.html` and `/support.html`, and
App Store Connect requires both. Those addresses currently serve the **old** product's pages,
which would fail review. The three files in `Web/` replace them.

27. **(owner)** Search `Web/index.html`, `Web/privacy.html` and `Web/support.html` for
    `<<OWNER` and fill in your legal name. The App Store link can wait until after release.
28. **(owner)** Publish them. In Git Bash, from the `nivli` folder:

    ```bash
    git clone https://github.com/bluepenguin1234/bluepenguin1234.github.io.git "$TEMP/pages"
    cp Web/*.html "$TEMP/pages/"
    git -C "$TEMP/pages" add -A
    git -C "$TEMP/pages" commit -m "Nivli 3.0 pages"
    git -C "$TEMP/pages" push
    ```

    Or open the `bluepenguin1234.github.io` repository on github.com and use **Add file**,
    **Upload files** with the three files. Either way they are live within a minute.
29. **(owner)** Open both addresses in a browser and check they show the new pages, not the
    memory app's. The privacy page must mention Apple Health and Screen Time, because the
    App Privacy answers point at it.

## I. The version page

30. **(owner)** App Store Connect, **Nivli**, **+ Version or Platform**, **iOS**, version
    **3.0.0**.
31. **(owner)** Fill in the fields from `AppStore/LISTING.md`, which has every string ready
    to copy: name, subtitle, promotional text, description, keywords, category (Health &
    Fitness primary, Productivity secondary), support and marketing URLs, copyright.
32. **(owner)** **What's New in This Version**: paste the block from
    `AppStore/RELEASE_NOTES.md`. Its first line has to say that 3.0 is a different product,
    because existing customers of the old Nivli will be updated into it.
33. **(owner)** **Age rating**: answer exactly as `AppStore/LISTING.md` sets out. Parental
    controls is **not** ticked (Nivli uses `.individual` authorization on the device's own
    user), every content descriptor is None, and the expected result is **4+**.
34. **(owner)** Set the remaining version-page options: iPhone only, minimum iOS 18.0,
    Content Rights "does not contain third-party content", **Manually release this version**,
    pricing **Free** with the subscription as an in-app purchase, and export compliance
    exempt (`ITSAppUsesNonExemptEncryption = NO` is already in the build, so it may not ask).
35. **(owner)** **In-App Purchases and Subscriptions** on the version page: add **Nivli+
    Monthly**. If the section will not let you, the product is not Ready to Submit; go back
    to step 18.

## J. Screenshots

36. **(owner)** Delete **every** 2.x screenshot first. They show a different product and
    would fail guideline 2.3.3 on their own.
37. **(owner)** Upload the six shots from step 26 into the **6.9-inch iPhone** slot, in the
    order `AppStore/SCREENSHOTS.md` lists them. Apple scales that set down for every other
    size, so leave the other slots empty unless you have native shots for them.
38. **(owner)** If your iPhone is not a Pro Max or Plus, upscale first with the Shortcuts
    recipe in `AppStore/SCREENSHOTS.md`, and check the resolution in Photos before uploading.
39. **(owner)** No App Preview video for 3.0.0.

## K. App Privacy

40. **(owner)** Sidebar, **App Privacy**, **Privacy Policy URL**:
    `https://bluepenguin1234.github.io/privacy.html`. Leave User Privacy Choices blank.
41. **(owner)** **Get Started**, then answer **"No, we do not collect data from this app"**.
    That is the whole questionnaire. The reasoning behind that answer, data type by data
    type, is in `AppStore/PRIVACY_QUESTIONNAIRE.md` if a reviewer ever asks.
42. **(owner)** **Publish** the answers. The product page should read **Data Not Collected**.

## L. Review information

43. **(owner)** On the version page, **App Review Information**. Sign-in required: **No**.
    Fill in your first name, last name, phone number and `suchanekbs@gmail.com`.
44. **(owner)** **Notes**: paste everything below the horizontal rule in
    `AppStore/REVIEW_NOTES.md`. It tells the reviewer to test on a physical iPhone, explains
    the `.individual` Screen Time authorization, walks the nine-step flow, and says that a
    shield cannot close an already-running app. No attachment is needed.

## M. Submit

45. **(owner)** Attach the build. Either pick the TestFlight build from step 21 on the
    version page, or run Codemagic's **iOS Release — Submit build to App Store Connect**
    workflow, which uploads and attaches a fresh one. That workflow uses
    `release_type: MANUAL`, so it never releases anything on its own.
46. **(owner)** Read the version page once more against `AppStore/LISTING.md`. The easiest
    things to get wrong are a leftover 2.x screenshot, an old subtitle, and the copyright
    field still holding a placeholder.
47. **(owner)** Press **Add for Review**, then **Submit for Review**.
48. **(owner)** Expect a first response in a day or two. If it is a rejection, send the
    exact text of Apple's message to your engineering session; most Screen Time and
    subscription rejections are answered with a reply in Resolution Center rather than a new
    build.

## N. After approval

49. **(owner)** Release it yourself: the version is set to **Manually release**, so nothing
    goes live until you press **Release this version**. Check the web pages from section H
    are still up first.
50. **(owner)** Watch App Store Connect, **App Analytics** and **Crashes**, for the first
    week. `Scripts/crash_summary.py` turns an Apple `.ips` crash report into the three lines
    that matter, if you ever need to send one on.
51. **(owner)** Keep an eye on Codemagic builds. Every push to `main` runs the fast compile
    check, so a broken change is visible within about eight minutes.
52. **(owner)** Optional, any time after release: a 7-day free trial is an App Store Connect
    change only, with no new build. The paywall reads the offer from StoreKit and writes its
    own copy from it. The last section of `AppStore/SUBSCRIPTION_SETUP.md` has the clicks and
    the one gotcha, which is that anyone who has ever subscribed to Nivli+ is not eligible.
53. **(owner)** Update `Web/index.html` with the real App Store link once the app is live,
    and push it the same way as step 28.
