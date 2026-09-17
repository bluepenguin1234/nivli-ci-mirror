#!/usr/bin/env python3
"""Render the Nivli app icon and related brand/asset-catalog files.

Usage:  python3 Scripts/render_icon.py      (no arguments, idempotent)

Requires only Pillow. Everything is rendered at 4x (4096 px) with hard edges
and downsampled with a Lanczos filter, which gives clean anti-aliasing without
cairo/rsvg/ImageMagick.

Outputs
  Nivli/Assets.xcassets/AppIcon.appiconset/AppIcon.png         light, opaque RGB
  Nivli/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png    iOS 18 dark, RGBA
  Nivli/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png  iOS 18 tinted, RGBA grayscale
  Nivli/Assets.xcassets/AppIcon.appiconset/Contents.json
  Nivli/Assets.xcassets/Contents.json
  Nivli/Assets.xcassets/{AccentColor,WidgetBackground}.colorset/Contents.json
  NivliWidgets/Assets.xcassets/... (same catalog root + colour sets, no AppIcon)
  Brand/Nivli-Icon.svg                                          light icon as SVG
  Brand/nivli-icon-preview.png                                  3-up review sheet
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------- brand values
SIZE = 1024                      # iOS marketing icon size
SS = 4                           # supersampling factor
INK = (0x14, 0x2B, 0x39)         # deep ink blue background
WHITE = (0xFF, 0xFF, 0xFF)       # the "N"
MINT = (0x5E, 0xDC, 0xC0)        # the "i" dot
TINT_DOT_GRAY = 190              # dot luminance in the tinted (grayscale) variant

# Glyph geometry on the 1024 grid, before centering.
# The stroke is the "N": up the left leg, diagonal down to the bottom right,
# then up the right leg (which stops short so the mint dot completes it
# into "Ni").  Same path as Brand/Nivli-Icon.svg: M304 708 V316 L720 708 V436.
N_POINTS = [(304, 708), (304, 316), (720, 708), (720, 436)]
STROKE = 92
DOT_CENTER = (720, 316)
DOT_RADIUS = 50

# Optical centering: the mark is centred on its true bounding box (stroke
# extents + dot), then lifted a touch because the N carries its weight in the
# lower half and a purely geometric centre reads as sitting too low.
OPTICAL_LIFT = 6


def _bbox():
    r = STROKE / 2
    xs = [x - r for x, _ in N_POINTS] + [x + r for x, _ in N_POINTS]
    ys = [y - r for _, y in N_POINTS] + [y + r for _, y in N_POINTS]
    xs += [DOT_CENTER[0] - DOT_RADIUS, DOT_CENTER[0] + DOT_RADIUS]
    ys += [DOT_CENTER[1] - DOT_RADIUS, DOT_CENTER[1] + DOT_RADIUS]
    return min(xs), min(ys), max(xs), max(ys)


def _offset():
    x0, y0, x1, y1 = _bbox()
    dx = SIZE / 2 - (x0 + x1) / 2
    dy = SIZE / 2 - (y0 + y1) / 2 - OPTICAL_LIFT
    return round(dx), round(dy)


DX, DY = _offset()
N_PTS = [(x + DX, y + DY) for x, y in N_POINTS]
DOT = (DOT_CENTER[0] + DX, DOT_CENTER[1] + DY)


# ------------------------------------------------------------------ rendering
def _circle(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)


def render_masks() -> tuple[Image.Image, Image.Image]:
    """Return (n_mask, dot_mask) as 1024x1024 anti-aliased 'L' images."""
    big = SIZE * SS
    n = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(n)
    w = STROKE * SS
    pts = [(x * SS, y * SS) for x, y in N_PTS]
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=255, width=w)
    for x, y in pts:                     # round caps and round joins
        _circle(d, x, y, w / 2)

    dot = Image.new("L", (big, big), 0)
    _circle(ImageDraw.Draw(dot), DOT[0] * SS, DOT[1] * SS, DOT_RADIUS * SS)

    return (n.resize((SIZE, SIZE), Image.LANCZOS),
            dot.resize((SIZE, SIZE), Image.LANCZOS))


def compose_opaque(n_mask, dot_mask, bg, n_color, dot_color) -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE), bg)
    img.paste(Image.new("RGB", (SIZE, SIZE), n_color), mask=n_mask)
    img.paste(Image.new("RGB", (SIZE, SIZE), dot_color), mask=dot_mask)
    return img


def compose_transparent(n_mask, dot_mask, n_color, dot_color) -> Image.Image:
    """Glyph on a fully transparent background with clean (un-fringed) edges.

    Colour is written as solid fills (the dot's colour covers every pixel the
    dot touches at all), and coverage lives only in the alpha channel, so
    partially covered edge pixels never blend towards a background colour.
    """
    rgb = Image.new("RGB", (SIZE, SIZE), n_color)
    dot_region = dot_mask.point(lambda v: 255 if v else 0)
    rgb.paste(Image.new("RGB", (SIZE, SIZE), dot_color), mask=dot_region)
    alpha = ImageChops.lighter(n_mask, dot_mask)
    r, g, b = rgb.split()
    return Image.merge("RGBA", (r, g, b, alpha))


# ------------------------------------------------------------------ SVG / JSON
def svg_text() -> str:
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = N_PTS
    path = f"M{x0} {y0}V{y1}L{x2} {y2}V{y3}"
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        'viewBox="0 0 1024 1024">\n'
        f'  <rect width="1024" height="1024" fill="#{INK[0]:02X}{INK[1]:02X}{INK[2]:02X}"/>\n'
        f'  <path d="{path}" fill="none" stroke="#FFFFFF" stroke-width="{STROKE}" '
        'stroke-linecap="round" stroke-linejoin="round"/>\n'
        f'  <circle cx="{DOT[0]}" cy="{DOT[1]}" r="{DOT_RADIUS}" '
        f'fill="#{MINT[0]:02X}{MINT[1]:02X}{MINT[2]:02X}"/>\n'
        '</svg>\n'
    )


XCODE_INFO = {"author": "xcode", "version": 1}


def appicon_contents() -> dict:
    def entry(filename, appearance=None):
        e = {}
        if appearance:
            e["appearances"] = [{"appearance": "luminosity", "value": appearance}]
        e.update({"filename": filename, "idiom": "universal",
                  "platform": "ios", "size": "1024x1024"})
        return e
    return {"images": [entry("AppIcon.png"),
                       entry("AppIcon-Dark.png", "dark"),
                       entry("AppIcon-Tinted.png", "tinted")],
            "info": XCODE_INFO}


def colorset_contents(light: tuple, dark: tuple) -> dict:
    def color(rgb):
        r, g, b = rgb
        return {"color-space": "srgb",
                "components": {"alpha": "1.000", "blue": f"{b:.3f}",
                               "green": f"{g:.3f}", "red": f"{r:.3f}"}}
    return {"colors": [
                {"color": color(light), "idiom": "universal"},
                {"appearances": [{"appearance": "luminosity", "value": "dark"}],
                 "color": color(dark), "idiom": "universal"}],
            "info": XCODE_INFO}


COLORSETS = {
    "AccentColor": ((0.067, 0.400, 0.365), (0.369, 0.863, 0.753)),
    "WidgetBackground": ((1.0, 1.0, 1.0), (0.11, 0.11, 0.118)),
}


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n")


def write_catalog(catalog: Path) -> list[Path]:
    written = []
    p = catalog / "Contents.json"
    write_json(p, {"info": XCODE_INFO})
    written.append(p)
    for name, (light, dark) in COLORSETS.items():
        p = catalog / f"{name}.colorset" / "Contents.json"
        write_json(p, colorset_contents(light, dark))
        written.append(p)
    return written


# -------------------------------------------------------------------- preview
def _rounded_mask(size: int) -> Image.Image:
    """iOS-style rounded corner mask (approximation of the squircle)."""
    big = size * SS
    m = Image.new("L", (big, big), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, big - 1, big - 1],
                                        radius=int(big * 0.2237), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def _tile(img: Image.Image, size: int) -> Image.Image:
    tile = img.convert("RGBA").resize((size, size), Image.LANCZOS)
    tile.putalpha(ImageChops.multiply(tile.getchannel("A"), _rounded_mask(size)))
    return tile


def simulate_dark(dark_icon: Image.Image) -> Image.Image:
    bg = Image.new("RGBA", dark_icon.size, (0x1C, 0x1C, 0x1E, 255))
    return Image.alpha_composite(bg, dark_icon)


def simulate_tinted(tinted_icon: Image.Image, tint=MINT) -> Image.Image:
    """Approximate iOS: dark gradient plate, glyph coloured by luminance x tint."""
    w, h = tinted_icon.size
    plate = Image.new("RGB", (w, h))
    top, bottom = (0x30, 0x30, 0x34), (0x14, 0x14, 0x16)
    px = plate.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    lum = tinted_icon.convert("L")
    alpha = ImageChops.multiply(tinted_icon.getchannel("A"), lum)
    glyph = Image.new("RGB", (w, h), tint)
    out = plate.copy()
    out.paste(glyph, mask=alpha)
    return out.convert("RGBA")


def build_preview(light, dark, tinted, tile=256) -> Image.Image:
    pad, gap, label_h = 40, 48, 44
    w = pad * 2 + tile * 3 + gap * 2
    h = pad * 2 + tile + label_h
    sheet = Image.new("RGBA", (w, h), (0xF2, 0xF2, 0xF4, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    items = [("Light", light.convert("RGBA")),
             ("Dark (on #1C1C1E)", simulate_dark(dark)),
             ("Tinted (simulated)", simulate_tinted(tinted))]
    for i, (label, img) in enumerate(items):
        x = pad + i * (tile + gap)
        sheet.alpha_composite(_tile(img, tile), (x, pad))
        tw = draw.textlength(label, font=font)
        draw.text((x + (tile - tw) / 2, pad + tile + 16), label,
                  fill=(0x3A, 0x3A, 0x3C, 255), font=font)
    return sheet


# ----------------------------------------------------------------------- main
def main() -> None:
    written: list[Path] = []

    n_mask, dot_mask = render_masks()
    light = compose_opaque(n_mask, dot_mask, INK, WHITE, MINT)
    dark = compose_transparent(n_mask, dot_mask, WHITE, MINT)
    tinted = compose_transparent(n_mask, dot_mask, (255, 255, 255),
                                 (TINT_DOT_GRAY,) * 3)

    iconset = ROOT / "Nivli/Assets.xcassets/AppIcon.appiconset"
    iconset.mkdir(parents=True, exist_ok=True)
    for name, img in (("AppIcon.png", light), ("AppIcon-Dark.png", dark),
                      ("AppIcon-Tinted.png", tinted)):
        p = iconset / name
        img.save(p, "PNG", optimize=True)
        written.append(p)
    p = iconset / "Contents.json"
    write_json(p, appicon_contents())
    written.append(p)

    written += write_catalog(ROOT / "Nivli/Assets.xcassets")
    written += write_catalog(ROOT / "NivliWidgets/Assets.xcassets")

    brand = ROOT / "Brand"
    brand.mkdir(parents=True, exist_ok=True)
    p = brand / "Nivli-Icon.svg"
    p.write_text(svg_text())
    written.append(p)
    p = brand / "nivli-icon-preview.png"
    build_preview(light, dark, tinted).save(p, "PNG", optimize=True)
    written.append(p)

    print(f"glyph offset dx={DX} dy={DY}; N={N_PTS}; dot={DOT} r={DOT_RADIUS}; "
          f"stroke={STROKE}")
    for p in written:
        print("wrote", p.relative_to(ROOT))


if __name__ == "__main__":
    main()
