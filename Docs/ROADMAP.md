# Roadmap

## 3.0 (this build) — solo

Lock the apps you chose until you have moved. Manual log or Apple Health. Streaks, rest
days, one subscription. No account, no server.

## 3.1 — Nivli Social (owner's idea, 16 Sep 2026, not started)

> "You post a picture when you are done, I give you props, you can share a picture of your
> watch or during your run, or after, and it's like a running or working out or biking
> platform."

### The loop

1. Unlock the day (as in 3.0), then the celebration offers **Post it**: a photo (the watch
   face, the trail, the gym mirror) with the workout summary stamped on it (42 min run ·
   day 12).
2. Friends see it in a simple feed and give **props** (one tap, a haptic, a count).
3. Props and streaks feed back into the Home screen: "3 friends moved today", "Sam gave you
   props".
4. Sharing out: the stamped photo exports to Instagram Stories / Messages with the Nivli
   mark, which is the growth engine.

### What it takes (why it is not in 3.0)

| Need | Why | Suggested answer |
|---|---|---|
| Accounts | A feed needs identity | Sign in with Apple only (fast, private, Apple-approved) |
| Backend | Photos, feed, friends, props | Supabase (Postgres + Storage + Auth + Row Level Security); ~$25/month at the start |
| Friend graph | Who sees what | Invite links and contact matching by hashed phone/email, opt-in |
| Photo storage | A few MB per post | Supabase Storage, downscaled to 1600 px on device before upload |
| Push notifications | "Sam gave you props" | APNs via the backend (the App ID needs Push again) |
| Apple guideline 1.2 (user-generated content) | Required for any UGC app | Report post, block user, hide, a moderation queue, 24-hour response, terms the user agrees to |
| Guideline 5.1.1(v) account deletion | Required when there is an account | Delete account in Settings, server wipes everything |
| Privacy label changes | Now "Data Linked to You" | Photos, user content, contacts (if matching), identifiers |
| Age rating | Social features | Stays 4+ if no open discovery; keep it friends-only at first |
| Health data rule | Never upload Health data | Only the stamped summary the person chooses to post, never raw Health records |

### Order of work

1. Backend and Sign in with Apple, account deletion, privacy policy update.
2. Post a photo after unlock, own timeline.
3. Friends by invite link, feed, props, push.
4. Report / block / moderation before submission.
5. Export to Stories with the stamp.

Estimated: 4–6 weeks of build plus App Review with UGC.

### What stays true

Solo use must keep working with no account, exactly as 3.0: social is a layer, never a
requirement, so the "no account" promise on the App Store page can stay for the free-of-
social path.
