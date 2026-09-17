# Nivli, in plain words

For the owner. This is what the app does, screen by screen, and what it cannot do. Nothing
here needs a Mac. If something on your iPhone does not match this page, that is a bug worth
reporting.

## What Nivli is

Nivli locks the apps you choose until you have worked out today. Log a workout by hand, or
let Apple Health prove it, and those apps open until midnight. Every day you move, the
streak goes up by one.

## The rules

These rules are the whole product. The app, the midnight extension and the lock screen over
a blocked app all read the same stored answers, so they cannot disagree with each other.

**What unlocks your apps.** One workout today that is at least as long as your minimum. The
minimum is set in onboarding and in Settings: 10, 15, 20, 30, 45 or 60 minutes. A new
install starts at 20. The kind of workout (run, walk, strength, cycle, swim, yoga, HIIT,
sport, other) changes the icon and the wording and nothing else. Only the number of minutes
decides.

**Minimum minutes.** A workout shorter than your minimum is still saved in your history. It
does not unlock anything, and the logging sheet says so before you save it: "Under your
20-minute minimum. It's saved, but your apps stay locked."

**The day boundary.** Your iPhone's own local calendar day, midnight to midnight. A workout
counts against the day it started on.

**Rest days.** Two kinds. Weekly rest days are weekdays you always rest on, set with seven
switches in Settings, and none are on to begin with. On a rest day nothing is locked, and
your streak is neither broken nor grown.

**Take today off.** One button in Settings, under Rest days, with a confirmation. It makes
today a rest day: nothing is locked until tomorrow, and the streak survives. Once you have
taken today off the button reads "Today is a rest day" and is greyed out. There is no undo
in the app, so the day stays a rest day until tomorrow.

**The streak.** Consecutive days ending today in which every day is either a qualifying
workout day or a rest day. Only the workout days are counted. Today is special: if today is
not done yet the streak is not broken, because the day is not over, so Nivli keeps counting
back from yesterday.

*A worked example.* Your minimum is 20 minutes and Sunday is a weekly rest day.

| Day | What happened | Counts? |
| --- | --- | --- |
| Friday | 30 minute run | Yes, 1 |
| Saturday | 25 minute strength | Yes, 2 |
| Sunday | Rest day, nothing logged | Bridges the gap, adds nothing |
| Monday | 40 minute cycle | Yes, 3 |
| Tuesday (today) | Nothing yet | Not counted, not broken |

Home reads "3" on Tuesday morning. Log 20 minutes or more on Tuesday and it reads "4". Let
Tuesday pass with nothing logged and on Wednesday it reads "0", because Tuesday was neither
a workout day nor a rest day. Your longest streak is kept separately and never goes down.

**What happens at midnight.** An iOS extension wakes at 00:00 every day and puts the shields
back on, whether or not Nivli is open. Yesterday's workout does not carry over. If the new
day is a rest day, or your subscription has lapsed, or nothing is selected, the extension
clears the shields instead of applying them.

**If the subscription lapses.** Nothing is locked. Nivli never shields the apps of someone
who is not paying. Your log, your streak and your settings are all still there, and the
apps lock again the moment you subscribe again. The shields drop the next time Nivli
refreshes, which is the next time you open it or the next midnight wake, not the exact
second the subscription expires. Home shows a card, "Your subscription ended", with "Start
again" and "Restore Purchases".

**If you delete the app.** iOS removes every shield Nivli applied. That is the system's own
behaviour, not something Nivli has to do, and it is why Nivli is a speed bump you agreed to
rather than a lock somebody else holds.

**What Nivli can see.** The kind and length of the workouts you log or that it reads from
Apple Health, your settings, and whether your selection is empty. That is all, and all of it
stays on the iPhone.

**What Nivli cannot see.** Which apps you picked. Apple's picker hands the app opaque
tokens that only iOS can turn back into an app, so Nivli cannot read a name, an icon or a
bundle identifier from one. It also never sees how long you use anything, what you do in
any app, or anything else in Apple Health beyond workouts.

## Every screen

### Welcome (onboarding 1 of 8)

The "Ni" mark breathing slowly on the dark canvas, "Move first. Then scroll.", and two lines
saying what the app does. Nothing to answer.

- **Get started**: goes to the next page.

### Goals (onboarding 2 of 8)

"What are you here for?" with five rows you can tap on and off: Build a workout habit, Cut
my screen time, Get stronger, Feel better day to day, Sleep better. These answers only ever
choose wording. They never change what the app does.

- **Continue**: greyed out until at least one is chosen.
- **Back arrow** (top left, on every page after this one): goes back one page.

### How often (onboarding 3 of 8)

"How often do you move now?" One answer: Rarely, 1 to 2 days a week, 3 to 4 days a week,
Almost every day.

- **Continue**: greyed out until you choose.

### Phone hours (onboarding 4 of 8)

"How much of your day goes to your phone?" One answer: About an hour, 2 hours, 3 hours or
more, I'd rather not know. After you choose, a card slides up with the same number as days
of a year: about 15, 30 or 46. Choosing "I'd rather not know" shows no card.

- **Continue**: greyed out until you choose.

### Apps that wait (onboarding 5 of 8)

"Choose the apps that wait", with a line saying Nivli never sees which apps you picked. What
the card shows depends on Screen Time.

- **Allow Screen Time**: shows Apple's own Screen Time prompt, once. This is the permission
  the whole app rests on.
- **Choose apps** (after permission): opens Apple's app picker. Pick single apps, whole
  categories, or websites. When you close it the card shows a summary like "3 apps · 1
  category · 2 sites" and the button becomes **Change apps**.
- If Screen Time was refused, or is unavailable (which in practice means a Simulator), the
  card explains it and you can carry on. Settings can retry later.
- **Continue**: enabled once something is picked, or straight away if Screen Time was
  refused or is unavailable. You can never be trapped on this page.

### Apple Health and minimum (onboarding 6 of 8)

"How will Nivli know you moved?" A card for Apple Health and a row of minute choices.

- **Connect Apple Health**: shows Apple's Health permission sheet, asking only to read
  workouts. Afterwards the card shows a "Connected" chip. Optional.
- **The minute picker**: 10, 15, 20, 30, 45, 60, with 20 selected. This is your minimum.
- **Continue**.

### Reminders (onboarding 7 of 8)

"Stay on track", with a time picker set to 6:00 pm.

- **Turn on reminders**: asks iOS for notification permission, then saves the time and moves
  on.
- **Not now**: moves on with reminders off. It is a real answer, not a second ask.

### Summary (onboarding 8 of 8)

"Your first streak starts today", then a card reading back your apps, your minimum, whether
Health is on, and your reminder time. Under it, seven dots with today lit.

- **Continue**: goes to the paywall.

### Paywall

Cannot be dismissed. The mark, "Unlock your apps by moving first", and three benefit rows:
the apps you chose stay shut, Apple Health unlocks them for you, streaks that make it stick.
Then the plan card: "Nivli", the price and period taken from the App Store at that moment,
and a "Cancel anytime" chip. If Apple ever offers a free trial on this product, the card
says so in its own line.

- **Start for $2.99 / month** (the wording follows the real price): buys the monthly plan.
- **Restore Purchases**: brings back a purchase from another device or an earlier install.
  An old yearly or lifetime purchase from the previous Nivli counts here.
- **Terms of Use** and **Privacy Policy**: open in the browser.
- The renewal paragraph under the buttons says the charge, the renewal and where to cancel.
- If the App Store cannot be reached the card is replaced by a short message and a **Try
  again** button. Cancelling a purchase shows "No charge was made."

Buying or restoring finishes onboarding, turns the shields on and goes to Home.

### Home

**The ring** at the top, with a word under it. It has five states.

| State | Ring and symbol | Words |
| --- | --- | --- |
| Locked | Empty ring, padlock | "Locked until you move" and "3 apps are waiting" |
| Unlocked | Ring filled in mint, tick | "Unlocked for today" and "42 min run · Apple Health" |
| Rest day | Ring filled in mint, leaf | "Rest day" and "Nothing is locked today" |
| Subscription ended | Empty ring, open padlock | "Subscription ended" and "Your apps are not locked" |
| No apps chosen | Empty ring, open padlock | "No apps chosen" and "Pick the apps that should wait" |

The ring only fills for a day that was won or deliberately rested, so an empty ring never
looks like an achievement. When your selection is categories or websites rather than named
apps, the locked line reads "Your chosen apps are waiting".

**The streak card**: a flame, today's streak as a big number, "Longest" on the right, and
the last seven days as dots. A filled dot with a tick is a day you moved, an outlined dot
with a leaf is a rest day, a plain grey dot is a missed day, and a mint outline is today
before you have moved. Today is never shown as missed.

**The primary button**: **Log a workout** while locked. Once the day is unlocked it becomes
a quieter **Add another**.

**The blocked apps card**, headed "Apps that wait": up to six app rows, then up to three
categories and three websites, each drawn by iOS with its own name and icon, then "+N more"
if there are others. **Edit** opens Apple's picker. With nothing picked the card reads
"Nothing is waiting yet" and offers **Choose apps**.

**Subscription ended card** (only when the subscription has lapsed): **Start again** reopens
the paywall, **Restore Purchases** checks for an existing purchase.

**The gear** at the top right opens Settings. Pulling the screen down refreshes it.

### Log a workout

A sheet. "Log a workout", then "Honor system. Nivli only works if you're straight with
yourself."

- **The kind grid**: nine tiles, run selected to begin with.
- **The duration row**: 10, 15, 20, 30, 45, 60, 90, plus a stepper underneath that moves in
  fives between 5 and 240 minutes. It opens on your minimum, so the common case is one tap.
- **The line underneath**: "Counts toward today", or the warning that it is under your
  minimum and your apps stay locked.
- **Log it**: saves it, closes the sheet, unlocks the day if it qualified.
- **Cancel**: closes without saving.

### Celebration

Shown when a logged workout actually unlocked the day. A tick springs in, "Unlocked.", and
"5-day streak". Landing exactly on 3, 7, 14, 30, 50, 100 or 365 days adds the number and a
shower of confetti. It clears itself after about two seconds, or on a tap. Logging a second
workout on a day that is already open does not show it.

### Settings

- **Apps that wait**: a row reading "3 apps · 1 category · 2 sites" that opens Apple's
  picker. If Screen Time has not been allowed yet, an **Allow Screen Time** row appears
  under it.
- **Apple Health**: **Connect Apple Health**, or "Connected" with a tick. Nivli cannot
  disconnect it for you, so the footnote tells you where to do it: Health, then Sharing,
  then Apps, then Nivli.
- **What counts**: the minimum workout, 10 to 60 minutes.
- **Rest days**: seven switches, Sunday through Saturday, then **Take today off** with a
  confirmation.
- **Reminders**: a switch for the evening reminder and, when it is on, the time.
- **Appearance**: Dark, Light or Match iPhone. Dark is the default.
- **Subscription**: the status ("Active · renews 14 Oct 2026", "Lifetime" or "Not active"),
  **Manage subscription** (Apple's own sheet), **Restore Purchases**, and **Start again**
  when there is no active subscription.
- **About**: Support, Privacy Policy, Terms of Use, and the version and build number.
- **Turn off Nivli and delete my data**: removes every lock, cancels the reminder, forgets
  the streak, the log and every setting, and takes you back to the first screen. There is a
  confirmation, and no undo.

### The shield (what iOS shows over a blocked app)

Not a Nivli screen: iOS draws it when you try to open something you picked. Dark ink
background, the Nivli mark, **Move first.**, and "Log a workout in Nivli to unlock Safari
today." When your streak is above zero a second line reads "Streak: 4 days. Keep it." One
mint **OK** button, which closes it.

### The two notifications

Both are local, both are optional, and there are no others.

- **"Apps unlocked"**, body "Workout detected. Streak: 4 days." Sent when Apple Health tells
  Nivli about a qualifying workout while the app is closed.
- **"Still locked"**, body "Your apps are waiting. Move, log it, and they open." The evening
  reminder, at your chosen time, and only on a day that is still locked.

## Pricing

One plan: $2.99 a month in the United States, and whatever Apple's own conversion is
elsewhere. The price always comes from the App Store at the moment the paywall is drawn, so
it is never wrong. There is no free tier, no advertising and nothing else to buy. It renews
automatically until cancelled, and you cancel it in your Apple Account settings.

The previous Nivli sold a yearly plan and a lifetime purchase. Those are off sale, but
anyone who bought one still gets in, on the paywall or in Settings, through Restore
Purchases.

## Privacy, in plain words

There is no account, no sign-up, no server of ours and no analytics. Nothing about you is
sent anywhere. The only network traffic in the whole app is Apple's App Store, for the
subscription.

The apps you pick arrive as opaque tokens that only iOS can resolve, so Nivli genuinely does
not know what they are. Workouts read from Apple Health are read on the iPhone and stay on
it, and Nivli never writes anything back to Health. Your log, your streak and your settings
live in Nivli's own storage on the phone, which means they are in your own iPhone backup and
nowhere else. The App Store privacy label is "Data Not Collected".

## Known limitations

These are real and worth knowing before anyone asks about them.

- **A shield cannot close an app that is already open.** iOS shields an app when it is
  opened. Something already running in the background will resume without the shield until
  it is quit from the App Switcher. Nivli says this on the App Store page rather than
  pretending otherwise.
- **The Simulator has no Screen Time.** Nothing about picking or shielding apps can be
  tested there. It has to be a real iPhone, which is why the device test exists.
- **Apple does not say whether Health was granted or refused.** iOS deliberately hides a
  refusal, so "Connected" only means the permission sheet was answered. If Health was
  actually refused, no workouts arrive and manual logging is the only way in. Everything
  still works, it is just quieter than expected.
- **The evening reminder is honest by rearrangement, not by cleverness.** A scheduled iOS
  notification cannot ask whether today is done. Nivli reschedules it every time something
  changes: while the day is still locked it is a daily reminder, and once the day is
  unlocked or turns out to be a rest day it becomes a one-off for tomorrow. Nivli refreshes
  whenever you open it and whenever Health delivers a workout, so in practice the nudge only
  reaches a day you have not finished. If nothing refreshes between the workout and the
  reminder time, it can still arrive on a day you moved.
- **Family Controls needs Apple's approval for distribution.** The Screen Time entitlement
  is granted per app. Development builds get it automatically, but TestFlight and App Store
  builds only after Apple approves a written request, which takes days to weeks. Nothing can
  be signed for TestFlight until that lands.
