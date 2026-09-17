# Decisions

Why Nivli 3.0 is built the way it is. Each entry says what was decided, why, and what it
costs. The design spec these came from is
`Docs/superpowers/specs/2026-09-16-nivli-move-first-design.md`. The owner was not available
during design, so every open question was answered by the build team and recorded here.
Anything here can be reversed; it is a decision, not a law.

## The bundle ID and the App Store record stay

**Decision.** Ship as version **3.0.0** of the existing app `com.bluepenguin.nivli`, under
the same App Store record, with the same App Group `group.com.bluepenguin.nivli`. The
extensions take `…nivli.monitor` and `…nivli.shield`.

**Why.** The record already exists, has an approved subscription under it and is already
associated with the developer account. A new record means a new app, a new review of the
subscription, and a second listing for the owner to maintain. The old product was a memory
app with very few users, so there is little to lose by replacing it.

**Trade-off.** Anyone who has the old Nivli installed is updated into a different product.
That is handled in copy, not in code: the What's New text and the App Store description both
open by saying so, and the review notes tell the reviewer before they find out for
themselves. There is no migration path from the old data, and none is offered.

## The existing subscription product is reused

**Decision.** Sell `com.bluepenguin.nivli.plus.monthly`, the $2.99 monthly product already in
the group "Nivli+". The yearly and lifetime products from the previous app are removed from
sale but still honoured as valid entitlements.

**Why.** A product id can never be changed or reused once created, and this one is already
approved and priced. Creating a new one would mean a fresh review of the in-app purchase for
no customer-visible gain. Honouring the old products is not generosity, it is the only
honest option: those people paid, and taking their access away to simplify the code would be
indefensible.

**Trade-off.** `AppConfig` has to carry three product ids where one would do, and
`SubscriptionStore.validUntil` has to handle a non-consumable (which maps to
`.distantFuture`) alongside subscriptions. Both are small and both are unit-tested. The
owner also has to do the App Store Connect edits in `AppStore/SUBSCRIPTION_SETUP.md`, which
is three screens of clicking.

## Hard paywall at the end of onboarding

**Decision.** No free tier. The eighth onboarding page is followed by a paywall that cannot
be dismissed except by subscribing or restoring.

**Why.** There is nothing sensible to give away. Nivli is one mechanism: shield the apps
until a workout lands. A free tier that shields fewer apps, or shields them for fewer days,
would be a worse product wearing a discount. One plan also means no comparison table, no
upgrade prompts inside the app, and no feature gate to maintain.

**Trade-off.** Conversion depends entirely on the eight onboarding pages, which is why page
4 turns phone hours into days of a year. It also means the paywall has to be flawless for
App Review: price and period from StoreKit, restore, renewal terms, Apple's standard EULA
and the privacy policy are all on the screen (guideline 3.1.2).

## Fail open, always

**Decision.** `ShieldPolicy` returns `.open` for five reasons, and the first three are
unsubscribed, not onboarded, and nothing selected. Anything unusual clears the shields. The
app never shields someone who has not paid.

**Why.** Three separate arguments point the same way. Ethically, an app that can hold
somebody out of their own phone must have a bias towards letting go. Practically, a bug that
fails closed is a support disaster that the person cannot even open the App Store to report.
And Apple would reject anything that kept shielding after a subscription lapsed.

**Trade-off.** Cancelling the subscription is a way to unlock the apps, and so is deleting
Nivli. That is accepted and said out loud on the App Store page: it is a speed bump you
agreed to, not a lock someone else holds. A stricter product would need a second person to
hold the key, and that is a different app.

## Manual logs are an honor system

**Decision.** A manual log takes a kind and a duration and is believed. There is no
verification, no timer, no proof.

**Why.** There is no way to verify a workout on an iPhone that is not either wrong (step
counts miss cycling, swimming and every lift) or hostile (a timer you must run means the
phone is in your hand at the gym). Apple Health is the honest verification path and it is
offered on the same page. Someone who wants to lie can lie in any design, so the design that
does not pretend is the better one.

**Trade-off.** The mechanism is only as good as the person's own intent, and the app says so
in the sheet: "Honor system. Nivli only works if you're straight with yourself." A workout
under the minimum is still saved, so the history stays true even when the day is not
unlocked.

## Rest days are first-class

**Decision.** Weekly rest days (seven switches) and a one-off "take today off". On a rest
day nothing is locked and the streak is neither broken nor grown.

**Why.** Rest is part of training, and a streak that punishes a rest day teaches the wrong
thing. Without rest days the only way to protect a streak is to lie in the log, which would
corrode the honor system the whole product rests on. Bridging rather than counting keeps the
number meaningful: a 30-day streak still means 30 workouts.

**Trade-off.** Two rules instead of one, and the `longestStreak` walk needs a bridge check
with a 400-day cap so a corrupt state cannot spin. "Take today off" has no undo in the
interface, which is deliberate: an undo would make it a toggle to flip whenever the evening
gets difficult.

## The selection is stored as opaque tokens, and that is the point

**Decision.** Apps are chosen with Apple's `FamilyActivityPicker` and stored as a
`FamilyActivitySelection`. Nivli asks it three questions only: is it empty, how many of each
kind, and please shield it.

**Why.** A token can only be resolved by iOS. That means the strongest privacy claim in the
app is structural rather than a promise: Nivli cannot learn which apps you picked, because
the information never reaches it. It is why the App Privacy answer is "Data Not Collected"
with nothing to argue about, and why the shield extension can draw an app's name without
Nivli ever knowing it.

**Trade-off.** The app cannot show a list of app names itself, cannot suggest apps, and
cannot test any of this off-device. `SwiftUI.Label(token)` asks the system to draw each row
on Home, ordered by hash so the rows do not shuffle between redraws. A unit test cannot mint
a token at all, which is why `NivliState` carries `selectionOverrideForTesting`.

## No widgets, no Siri, no Watch app, no sharing

**Decision.** None of them in 3.0.

**Why.** YAGNI. A widget would show a number that Home already shows, on a screen the person
is trying to use less. Siri has nothing to say that two taps do not say faster. A Watch app
would need a second target, a second review surface and a sync story, to log a workout that
Apple Health already reports on its own. Each one is an extra bundle, an extra entitlement
and an extra thing to break in review.

**Trade-off.** The previous Nivli had widgets, and its `com.bluepenguin.nivli.widgets` and
`…share` App IDs still exist in the developer account. They are left alone rather than
deleted, so adding a widget later costs nothing in the portal.

## iOS 18.0 floor, iPhone only, portrait only

**Decision.** `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `TARGETED_DEVICE_FAMILY = 1`, portrait,
`UIRequiresFullScreen = YES`.

**Why.** The app is built on `@Observable`, the current Screen Time API surface and StoreKit
2, all of which are comfortable on iOS 18. There is no iPad story worth telling, because
Screen Time shielding on a shared device raises questions the product does not answer, and
there is no landscape layout worth designing for a single scrolling column. Apple's own
upload check wants both the generic and the iPhone orientation keys, and a portrait-only app
must opt out of iPad multitasking or Apple demands all four orientations.

**Trade-off.** iPhones stuck on iOS 17 cannot install it. Given the Screen Time dependency,
that is a small population.

## Swift 5 language mode

**Decision.** `SWIFT_VERSION = 5.0` with `SWIFT_STRICT_CONCURRENCY = minimal`.

**Why.** The code is written on a Windows machine and first compiled on a cloud Mac. Swift 6
turns data-race diagnostics into errors, which would mean discovering a migration through a
sequence of 15-minute cloud builds. Swift 5 keeps them as warnings so the first build fails
only for real mistakes. The concurrency discipline is still there in the code: `AppModel` and
the two observable services are `@MainActor`, and the types that cross actors are marked
`@unchecked Sendable` with a comment saying why.

**Trade-off.** A Swift 6 migration is deferred, not avoided. It should be done once there is
a Mac, or at least once the first builds are reliably green.

## XcodeGen and Codemagic, with no committed project file

**Decision.** `project.yml` is the source of truth. `Nivli.xcodeproj` is generated on the
build machine and is in `.gitignore`. All building, testing, signing and uploading happens
on Codemagic.

**Why.** There is no Mac. A committed `.xcodeproj` is an unreadable, merge-hostile file that
nobody here could open to fix, and it drifts from reality the moment a file is added.
`project.yml` is 150 readable lines that a person can review in a pull request, and every
setting in it carries a comment explaining what Apple rejects without it. Codemagic runs
Apple's own toolchain for free on the plan the owner is on.

**Trade-off.** Nothing can be compiled locally. The loop is push, wait about eight minutes,
read the first line containing `error:`. `Scripts/preflight.py` exists to catch everything
that does not need a compiler (plists, entitlements, assets, imports, secrets, listing
limits) before a build minute is spent on it.

## Build numbers start at 100 plus the Codemagic counter

**Decision.** `agvtool new-version -all "$((100 + BUILD_NUMBER))"`.

**Why.** The previous Nivli uploaded builds up to number 14 under the same App Store record.
App Store Connect rejects a build number it has already seen for a version train, and
Codemagic's counter starts at 1 for a new application. The offset makes a collision
impossible without anybody having to remember the old numbers.

**Trade-off.** Build numbers do not start at 1, which looks odd in TestFlight for about a
day and then stops mattering.

## A named ManagedSettingsStore

**Decision.** Every shield goes through `ManagedSettingsStore(named: "nivli.daily")`, never
the unnamed default store.

**Why.** `clearAllSettings()` is the only clean way to remove a shield, and on the unnamed
store it would wipe managed settings that another app or a configuration profile had put on
the device. A named store is Nivli's own container: clearing it is safe by construction, and
no code has to remember exactly which keys it set.

**Trade-off.** None worth mentioning. The name is a constant in `SharedConstants` because the
app and the monitor extension have to agree on it exactly, and a typo would silently split
them into two stores.

## The evening reminder is kept honest by rescheduling it

**Decision.** `NotificationService.scheduleEveningNudge(minutesFromMidnight:skipToday:)`.
While the day is locked it is a repeating daily trigger. Once the decision is not `.locked`,
`AppModel.rescheduleNudge()` replaces it with a single non-repeating trigger dated tomorrow.

**Why.** The copy promises "only on the days you have not moved yet", and a scheduled local
notification cannot ask a question at delivery time. There is no notification-service
extension that could suppress a local notification either. Rescheduling is the only
mechanism that can keep the promise, and `AppModel` already recomputes on every foreground,
every write and every Health delivery, so the hook was free.

**Trade-off.** It is not airtight. If nothing causes a refresh between a Health workout
landing and the reminder time, tonight's nudge still fires. In practice the Health delivery
itself is a refresh, so the gap is narrow. This limitation is written down in
`Docs/PRODUCT.md` rather than hidden.

## The HealthKit observer is registered in `NivliApp.init`

**Decision.** `AppModel.prepareForLaunch()` is called synchronously from the app's
initialiser, before any view exists, and again from `start()`.

**Why.** HealthKit background delivery wakes the app's process and then expects to find an
`HKObserverQuery` already registered. If the observer is only created by a view's `.task`,
a background launch has no observer at the moment the delivery arrives, and the whole
promise of "a Watch run unlocks your apps before you are back indoors" quietly stops
working. iOS may launch Nivli into the background for exactly this reason, so registration
cannot wait for the first screen.

**Trade-off.** It forces an ordering constraint in `NivliApp.init`: the `-nivli-reset` launch
argument has to empty the App Group before `AppModel` is built, which is why the model is
constructed in the initialiser body rather than as a property default. The initialiser is
also doing more work than an initialiser usually should, so both facts carry comments in the
code.
