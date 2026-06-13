"""Remove green-screen spill, preserve shadows, and add safe padding to car PNG assets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ASSET_DIR = Path(__file__).parent


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


def add_safe_padding(
    img: Image.Image,
    *,
    min_horizontal: int = 24,
    min_top: int = 12,
    min_bottom: int = 20,
) -> Image.Image:
    """Expand canvas so wheels, mirrors, and ground shadows are never clipped."""
    img = img.convert("RGBA")
    bbox = img.getbbox()
    if not bbox:
        return img

    left, top, right, bottom = bbox
    width, height = img.size

    pad_left = min_horizontal if left <= 4 else 8
    pad_right = min_horizontal if right >= width - 5 else 8
    pad_top = min_top if top <= 4 else 8
    pad_bottom = min_bottom if bottom >= height - 5 else min_bottom

    canvas = Image.new(
        "RGBA",
        (width + pad_left + pad_right, height + pad_top + pad_bottom),
        (0, 0, 0, 0),
    )
    canvas.paste(img, (pad_left, pad_top), img)
    return canvas


def process_file(path: Path) -> None:
    img = Image.open(path)
    img = remove_green_background(img)
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
