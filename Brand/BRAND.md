# Nivli brand

**Name:** Nivli  ·  **Tagline / App Store subtitle:** *Remember when.*

Nivli remembers when you last did something and reminds you when it's time again.
The brand should feel calm, reliable and a little warm — a memory, not a task manager.

## Icon
The mark is "Ni": a single white **N** stroke with round caps (stroke width 92 on the
1024 grid) whose right leg stops short, and a **mint dot** that completes it into an "i".
The dot is the moment something happened — the thing Nivli keeps for you.
It sits on deep ink blue; no gradients, no shadows, no lettering, no bevels.

- Source of truth: `Scripts/render_icon.py` (Pillow, 4x supersampled). Run it with
  `python3 Scripts/render_icon.py`; never hand-edit the PNGs.
- `Nivli/Assets.xcassets/AppIcon.appiconset/` holds the iOS 18 set: light (opaque ink),
  dark (glyph only, transparent — iOS supplies the dark plate) and tinted (grayscale glyph).
- `Brand/Nivli-Icon.svg` is the light icon as vector; `Brand/nivli-icon-preview.png` is a 3-up.

## Colours
| Role | Light | Dark |
|---|---|---|
| Ink (icon background, brand dark) | `#142B39` | `#142B39` |
| Mint (icon dot, brand highlight) | `#5EDCC0` | `#5EDCC0` |
| Accent (`AccentColor` in-app tint) | teal `#11665D` (0.067, 0.400, 0.365) | mint `#5EDCC0` (0.369, 0.863, 0.753) |
| Widget background (`WidgetBackground`) | white `#FFFFFF` | `#1C1C1E` (0.11, 0.11, 0.118) |

Mint is too light for text on white, which is why the in-app accent is the deeper teal in
light mode and switches to mint in dark mode. Both colour sets live in the app and widget
asset catalogs and must stay identical.

## Typography
- System font (SF) everywhere; rely on Dynamic Type styles, no custom fonts.
- Elapsed-time displays ("3 months ago", "14 days") use **rounded** design
  (`.fontDesign(.rounded)`) with monospaced digits so numbers don't jitter as they change.
- Titles are sentence case. Avoid all caps except small section headers.

## Do
- Keep the icon exactly as generated; use the SVG for marketing, the PNGs for the app.
- Use ink on white or white on ink; use mint sparingly as the one highlight.
- Keep copy short and human: "Last: 3 months ago", "Did it", "Tomorrow".

## Don't
- Don't add gradients, shadows, glows, badges, text or a second mark to the icon.
- Don't recolour the dot or stretch the N; don't place the mark on busy photos.
- Don't use mint as body text or on light backgrounds in the app.
- Don't call the app a to-do list or task manager; it is a memory for recurring things.

## The kit (added 12 Sep 2026)

`Brand/brand-sheet.html` shows the mark, icon, colours, type and the app building blocks in both looks, with the rules and a file list. The exports are generated from the icon geometry:

- `icon/` square PNGs (1024 to 60) for Apple surfaces and rounded PNGs/SVG (512 to 16) for the web and documents.
- `mark/` the mark alone, ink and white, plus the overdue (attention) state, as SVG and PNG.
- `favicon/` favicon.svg, favicon-32.png, favicon-16.png and apple-touch-icon-180.png for the website.

Regenerate with the kit script kept alongside `Scripts/render_icon.py`; edit the geometry, never the exports.
