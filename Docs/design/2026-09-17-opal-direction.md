# Nivli 3.0 — techy, futuristic, still minimal

2026-09-17. Direction for the "more techy and futuristic, like Opal" pass. One page.

## 1. What the research actually said

### iOS/SwiftUI design skill repos

Five public skill repos were read end to end. The useful ones:

| Repo | What it is good for |
|---|---|
| `time-attack/ada-swiftui-design` | Hero scale, numerals, banned patterns. Distilled from Apple Design Award winners. |
| `kalub92/eminence` | The most rigorous spacing, type, contrast and dark-mode doctrine found. |
| `heyparsadev/liquid-glass-skill` | Concrete glass numbers: radii, padding, tint rules, a11y ladder. |
| `zsed3d3-droid/ios-swiftui-design-skill` | Plain HIG baseline. Useful sanity check. |
| `Wholiver/swiftui-design-skill` | Colour rules sound; its fixed-pt type table is an anti-example. |

Rules that recurred in three or more of them, and that we adopt:

1. Never a fixed font size without `@ScaledMetric` or `relativeTo:`.
2. Contrast is arithmetic on the **composited** pair: ≥ 4.5:1 body, ≥ 3:1 for ≥18pt/bold and for icons and borders.
3. State is never colour-only — always a symbol or a word beside the hue.
4. **One accent.** Identity comes from type, layout, motion and light, not from a second hue.
5. A radius *scale*, not one radius: 12 / 16 / 20, always `.continuous`.
6. Hairlines over dark live at white 8–10%. Glows are a **coloured** shadow, never a black one — a black shadow on a dark ground is invisible paint.
7. All changing numbers get `.monospacedDigit()` and `.contentTransition(.numericText())`.
8. Track only the ALL-CAPS micro-label register, +0.8 to +1.5pt. Never track prose.
9. Springs answer fingers; eased curves answer data. Reduce Motion routes through one place.
10. Material is chrome over *imagery*. **A material over one flat colour is just a tint** — it needs something behind it to refract. Under Reduce Transparency, substitute an opaque surface.
11. Decorative layers get `.accessibilityHidden(true)` and `.allowsHitTesting(false)`.

Rule 10 is the load-bearing one for us: glass cards are only worth having **because** we put a lit canvas behind them. Glass over flat navy would have been decoration with no payoff.

### Opal, as actually evidenced

Opal publishes a brand kit (`brandkit.opal.so`). It contradicts the popular mental image in three places, and this is worth recording so nobody "corrects" our direction toward it later:

- Opal's canvas is **pure `#000000`**, not a navy gradient. Surfaces are `#3A3A3A`.
- Opal **bans gradients as backgrounds** in writing, and bans glows on brand assets. Its five pastel gradients are reserved for milestone reveal moments only.
- Opal's home hero is a **percentage plus an hourly bar chart**, not a progress ring. Its type is SF Pro Text with negative tracking; no rounded, no mono specified.
- Card radius, blur usage and glass treatment are **not established** by any source I could reach. Mobbin 403'd.

What *is* evidenced and worth stealing: austere 95% of the time so the reward moment lands; hierarchy from scale contrast rather than decoration; semantic colour confined to the data layer; spring-physics motion; heavily polished single reward moment.

**Decision:** we take Opal's *restraint and reward structure*, not its literal palette. Nivli keeps its navy canvas and mint — that is the brand, and a pure-black clone would cost us our identity for nothing. The soft light and glass in this direction are Nivli's own move, informed by the skill repos, not a copy of Opal's.

## 2. Tokens

### Colour

| Token | Night | Day | Use |
|---|---|---|---|
| `nivliCanvas` | `#08131C` | `#E4ECEE` | Flat fallback: launch, toolbars, keyboard strip |
| `nivliSurface` | `#10202B` | `#FFFFFF` | Solid cards and list rows |
| `nivliRaised` | `#162B3B` | `#F0F5F6` | A surface on a surface |
| `nivliLine` | white 8% | black 8% | Hairline between rows |
| `Theme.glassStroke` | white 8% | black 6% | The edge of a glass pane |
| accent | mint `#5EDCC0` | teal `#11665D` | **The only control colour** |
| `nivliAccentHighlight` | `#A9F3E2` | `#2EA894` | The lit end of the accent, gradients only |
| `NivliPalette.lightMint` | `#5EDCC0` | — | Glow orb, upper-left |
| `NivliPalette.lightViolet` | `#7C6CF6` | — | Glow orb, lower-right. **Light only, never a control.** |

Glow opacity ceilings: mint orb 18% night / 7% day; violet orb 10% night / 5% day; every element glow 35% night, and `Theme.glowOpacity(_:in:)` clamps Light mode to **8%** in one place.

### Type

- **Display numerals** — SF Rounded, bold, `.monospacedDigit()`. `Theme.numeral(_:)` or `.system(size:weight:design: .rounded)` behind a `@ScaledMetric`.
- **Telemetry** — `Theme.telemetry` = `.caption2.weight(.semibold).monospaced()`, uppercased, `.tracking(1.2)`. Applied only through `TelemetryLabel`, which hands VoiceOver the original words so "DAY STREAK" is never spelled out.
- **Everything else** — SF Pro at the standard text styles. Body text is never styled below `.subheadline`.

Three voices per screen, no more: rounded display, telemetry, system body.

### Surfaces, radii, motion

- Glass = `.ultraThinMaterial` over `NivliGlow`, radius `Theme.glassRadius` = 20, plus a 1px `Theme.glassStroke` hairline. Falls back to `nivliSurface` under Reduce Transparency.
- Radius scale: 12 (small controls) / 16 (rows, buttons) / 20 (glass panes) / capsule (chips).
- Selection: accent 12% fill + accent hairline + accent shadow at 18%.
- Motion: 0.15s ease for selection; `.spring(response: 0.25, damping: 0.8)` for presses; `.spring(response: 0.8)` for the ring settling; one 1.2s eased pulse in the celebration, once. Every new animation is behind `accessibilityReduceMotion`.

## 3. Do not

- No neon everywhere. Light is a background condition and a hero accent; it is never on a card, a row of text, or more than one element per screen.
- No gradients on text. The only gradients in the app are the arc's two-value accent sweep and the button's top hairline.
- No second control colour. The violet is light, never paint.
- No glass on glass, and no glass over a flat fill.
- No `repeatForever` decoration beyond the mark's existing breath.
- Body text stays ≥ 4.5:1 against the **composited** background in both modes. White text never sits on light glass — use `.primary` / `.secondary` everywhere.
- No fixed point sizes without `@ScaledMetric`.
