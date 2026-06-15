"""Remove green-screen spill, defringe edges, and tight-crop car PNG assets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageFilter

ASSET_DIR = Path(__file__).parent
ALPHA_CUTOFF = 40
EDGE_FEATHER_RADIUS = 0.0


def remove_green_background(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue

            spill = g - max(r, b)
            if spill > 80 and g > 140:
                pixels[x, y] = (r, g, b, 0)
                continue

            if spill > 35 and g > 100:
                alpha = max(0, min(255, int(255 - spill * 3.2)))
                pixels[x, y] = (r, g, b, min(a, alpha))
                continue

            if spill > 12 and a > 0:
                corrected_g = int(g - spill * 0.92)
                corrected_g = max(min(corrected_g, 255), min(r, b))
                pixels[x, y] = (r, corrected_g, b, a)

    return img


def _content_bbox(img: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = img.convert("RGBA").split()[3]
    return alpha.point(lambda value: 255 if value > ALPHA_CUTOFF else 0).getbbox()


def defringe_edges(img: Image.Image) -> Image.Image:
    """Remove colored halos on semi-transparent edge pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if a < ALPHA_CUTOFF:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if a < 220:
                factor = a / 255.0
                pixels[x, y] = (int(r * factor), int(g * factor), int(b * factor), a)

    if EDGE_FEATHER_RADIUS > 0:
        alpha = img.split()[3].filter(ImageFilter.GaussianBlur(radius=EDGE_FEATHER_RADIUS))
        rgb = img.convert("RGB")
        img = Image.merge("RGBA", (*rgb.split(), alpha))

    return img


def tight_crop(
    img: Image.Image,
    *,
    pad_left: int = 10,
    pad_right: int = 10,
    pad_top: int = 8,
    pad_bottom: int = 16,
) -> Image.Image:
    bbox = _content_bbox(img)
    if not bbox:
        return img

    left, top, right, bottom = bbox
    width, height = img.size
    left = max(0, left - (pad_left if left <= 6 else 6))
    right = min(width, right + (pad_right if right >= width - 7 else 6))
    top = max(0, top - (pad_top if top <= 6 else 6))
    bottom = min(height, bottom + (pad_bottom if bottom >= height - 7 else 10))
    return img.crop((left, top, right, bottom))


def add_safe_padding(
    img: Image.Image,
    *,
    min_horizontal: int = 16,
    min_top: int = 8,
    min_bottom: int = 14,
) -> Image.Image:
    """Small canvas padding so wheels and mirrors are never clipped in the UI."""
    img = img.convert("RGBA")
    bbox = _content_bbox(img)
    if not bbox:
        return img

    left, top, right, bottom = bbox
    width, height = img.size

    pad_left = min_horizontal if left <= 4 else 6
    pad_right = min_horizontal if right >= width - 5 else 6
    pad_top = min_top if top <= 4 else 6
    pad_bottom = min_bottom if bottom >= height - 5 else min_bottom

    canvas = Image.new(
        "RGBA",
        (width + pad_left + pad_right, height + pad_top + pad_bottom),
        (0, 0, 0, 0),
    )
    canvas.paste(img, (pad_left, pad_top), img)
    return canvas


def harden_alpha_edges(img: Image.Image) -> Image.Image:
    """Snap weak fringe pixels to fully transparent to avoid side halos in the UI."""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if a < 96:
                pixels[x, y] = (0, 0, 0, 0)
            elif a < 200:
                spill = g - max(r, b)
                if spill > 8 or max(r, g, b) - min(r, g, b) < 18:
                    pixels[x, y] = (0, 0, 0, 0)
                else:
                    pixels[x, y] = (r, g, b, 255)

    return img


def process_file(path: Path) -> None:
    img = Image.open(path)
    img = remove_green_background(img)
    img = defringe_edges(img)
    img = harden_alpha_edges(img)
    img = tight_crop(img)
    img = add_safe_padding(img)
    img.save(path, "PNG", optimize=True)
    print(f"cleaned {path.name} -> {img.size}")


def main() -> None:
    for path in sorted(ASSET_DIR.glob("*.png")):
        if "raw" in path.name:
            continue
        process_file(path)


if __name__ == "__main__":
    main()
