"""Generates the Puzzle Master app icons (a golden jigsaw piece).

Run from the repository root:  python tool/generate_app_icon.py
Requires Pillow. Writes Android, web, iOS, macOS and Windows icons.
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BIG = 2048  # master resolution; everything is downsampled from here

BG_TOP = (74, 35, 140)
BG_BOTTOM = (28, 16, 66)
PIECE_LIGHT = (255, 224, 102)
PIECE_DARK = (245, 142, 20)
OUTLINE = (125, 62, 6)


def _gradient(size, top, bottom):
    img = Image.new("RGB", (size, size), top)
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        draw.line(
            [(0, y), (size, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)),
        )
    return img


def _piece_mask(size, scale):
    """Jigsaw piece: a square with tabs on top/right and blanks left/bottom."""
    s = size * scale
    cx = cy = size / 2
    half = s * 0.5
    r = s * 0.17  # knob radius
    reach = s * 0.12  # how far the knob centre sits from the edge
    neck = s * 0.09
    # Tabs stick out top and right; shift so the piece looks centred.
    ox, oy = -s * 0.145, s * 0.145
    left, top = cx - half + ox, cy - half + oy
    right, bottom = cx + half + ox, cy + half + oy
    mid_x, mid_y = (left + right) / 2, (top + bottom) / 2

    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    rad = s * 0.08
    d.rounded_rectangle([left, top, right, bottom], radius=rad, fill=255)
    # Tabs out.
    d.ellipse([right + reach - r, mid_y - r, right + reach + r, mid_y + r], fill=255)
    d.rectangle([right - 2, mid_y - neck, right + reach, mid_y + neck], fill=255)
    d.ellipse([mid_x - r, top - reach - r, mid_x + r, top - reach + r], fill=255)
    d.rectangle([mid_x - neck, top - reach, mid_x + neck, top + 2], fill=255)
    # Blanks in.
    d.ellipse([left + reach - r, mid_y - r, left + reach + r, mid_y + r], fill=0)
    d.rectangle([left - 2, mid_y - neck, left + reach, mid_y + neck], fill=0)
    d.ellipse([mid_x - r, bottom - reach - r, mid_x + r, bottom - reach + r], fill=0)
    d.rectangle([mid_x - neck, bottom - reach, mid_x + neck, bottom + 2], fill=0)
    return mask


def _piece_layer(size, scale, shadow=True):
    """RGBA layer with the shaded piece (and a soft drop shadow)."""
    mask = _piece_mask(size, scale)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if shadow:
        sh = mask.filter(ImageFilter.GaussianBlur(size * 0.02))
        sh = ImageChops.offset(sh, round(size * 0.012), round(size * 0.025))
        shadow_img = Image.new("RGBA", (size, size), (10, 4, 30, 0))
        shadow_img.putalpha(sh.point(lambda v: v * 0.55))
        layer = Image.alpha_composite(layer, shadow_img)
    fill = _gradient(size, PIECE_LIGHT, PIECE_DARK).convert("RGBA")
    # Glossy highlight towards the top left.
    gloss = Image.new("L", (size, size), 0)
    ImageDraw.Draw(gloss).ellipse(
        [size * 0.18, size * 0.12, size * 0.62, size * 0.5], fill=110)
    gloss = gloss.filter(ImageFilter.GaussianBlur(size * 0.06))
    white = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    fill = Image.composite(white, fill, ImageChops.multiply(gloss, mask))
    # Outline: the mask minus a slightly eroded copy.
    inner = mask.filter(ImageFilter.MinFilter(max(3, (size // 110) | 1)))
    outline = ImageChops.subtract(mask, inner)
    fill.putalpha(mask)
    layer = Image.alpha_composite(layer, fill)
    edge = Image.new("RGBA", (size, size), OUTLINE + (255,))
    edge.putalpha(outline)
    return Image.alpha_composite(layer, edge)


def _rounded(img, radius_frac):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1],
        radius=round(img.size[0] * radius_frac), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def full_bleed(scale=0.46):
    """Opaque square icon: background plus piece (iOS, maskable, adaptive)."""
    bg = _gradient(BIG, BG_TOP, BG_BOTTOM).convert("RGBA")
    return Image.alpha_composite(bg, _piece_layer(BIG, scale))


def rounded_icon(scale=0.5, margin=0.0, radius=0.22):
    icon = _rounded(full_bleed(scale), radius)
    if margin:
        canvas = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
        inner = round(BIG * (1 - 2 * margin))
        canvas.paste(icon.resize((inner, inner), Image.LANCZOS),
                     (round(BIG * margin),) * 2)
        icon = canvas
    return icon


def save(img, path, size, mode=None):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if mode:
        out = out.convert(mode)
    out.save(path)


def main():
    # The piece with its tabs spans about 1.3 x scale of the canvas.
    legacy = rounded_icon(scale=0.5, margin=0.04)
    opaque = full_bleed(scale=0.5)
    maskable = full_bleed(scale=0.4)  # keeps the piece inside the safe zone
    foreground = _piece_layer(BIG, 0.36)  # adaptive icons: 66/108 safe zone
    background = _gradient(BIG, BG_TOP, BG_BOTTOM)
    mono_mask = _piece_mask(BIG, 0.36)
    monochrome = Image.new("RGBA", (BIG, BIG), (255, 255, 255, 0))
    monochrome.putalpha(mono_mask)

    res = "android/app/src/main/res"
    for density, legacy_size, adaptive_size in [
        ("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216),
        ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432),
    ]:
        save(legacy, f"{res}/mipmap-{density}/ic_launcher.png", legacy_size)
        save(foreground, f"{res}/mipmap-{density}/ic_launcher_foreground.png", adaptive_size)
        save(background, f"{res}/mipmap-{density}/ic_launcher_background.png", adaptive_size)
        save(monochrome, f"{res}/mipmap-{density}/ic_launcher_monochrome.png", adaptive_size)

    save(rounded_icon(), "web/icon-192.png", 192)
    save(rounded_icon(), "web/icon-512.png", 512)
    save(maskable, "web/icon-192-maskable.png", 192, "RGB")
    save(maskable, "web/icon-512-maskable.png", 512, "RGB")
    save(opaque, "web/apple-touch-icon.png", 180, "RGB")
    favicon = rounded_icon(scale=0.56, radius=0.2)
    favicon.resize((64, 64), Image.LANCZOS).save(
        ROOT / "web/favicon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])

    ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name in (ROOT / ios).glob("Icon-App-*.png"):
        dims = name.stem.split("-")[-1].split("@")
        points, factor = float(dims[0].split("x")[0]), int(dims[1][0])
        save(opaque, f"{ios}/{name.name}", round(points * factor), "RGB")

    mac = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    mac_icon = rounded_icon(margin=0.09)
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save(mac_icon, f"{mac}/app_icon_{size}.png", size)

    rounded_icon(scale=0.54, radius=0.2).resize((256, 256), Image.LANCZOS).save(
        ROOT / "windows/runner/resources/app_icon.ico",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])


if __name__ == "__main__":
    main()
