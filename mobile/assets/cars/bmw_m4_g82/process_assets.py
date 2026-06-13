"""Process raw BMW M4 G82 renders: chroma key removal, crop, normalize proportions."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ASSET_DIR = Path(__file__).parent
RAW_DIR = Path(__file__).resolve().parents[3] / "assets"  # .cursor/projects/.../assets

REFERENCE_HEIGHT = 400

# Target width:height ratios from BMW M4 G82 dimensions
ASPECT_RATIOS = {
    "side_right": 4794 / 1393,
    "side_left": 4794 / 1393,
    "front": 1887 / 1393,
    "rear": 1887 / 1393,
    "three_quarter_right": 2.2,
    "three_quarter_left": 2.2,
}

OUTPUT_NAMES = {
    "side_right_white_raw.png": "side_right_white.png",
    "side_right_black_raw.png": "side_right_black.png",
    "side_right_neutral_raw.png": "side_right_neutral.png",
    "side_left_white_raw.png": "side_left_white.png",
    "side_left_black_raw.png": "side_left_black.png",
    "front_white_raw.png": "front_white.png",
    "front_black_raw.png": "front_black.png",
    "rear_white_raw.png": "rear_white.png",
    "rear_black_raw.png": "rear_black.png",
    "three_quarter_right_white_raw.png": "three_quarter_right_white.png",
    "three_quarter_right_black_raw.png": "three_quarter_right_black.png",
    "three_quarter_left_white_raw.png": "three_quarter_left_white.png",
    "three_quarter_left_black_raw.png": "three_quarter_left_black.png",
}


def view_key(filename: str) -> str:
    for key in ASPECT_RATIOS:
        if filename.startswith(key):
            return key
    raise ValueError(f"Unknown view for {filename}")


def remove_green_background(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Chroma key: strong green dominance
            if g > 160 and g > r + 40 and g > b + 40:
                pixels[x, y] = (r, g, b, 0)
            elif g > 120 and g > r + 25 and g > b + 25:
                # Soft edge feathering
                alpha = max(0, min(255, int((g - max(r, b)) * 4)))
                pixels[x, y] = (r, g, b, 255 - alpha)

    return img


def crop_to_content(img: Image.Image, padding: int = 24) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def normalize_proportions(img: Image.Image, view: str) -> Image.Image:
    ratio = ASPECT_RATIOS[view]
    target_h = REFERENCE_HEIGHT
    target_w = int(round(target_h * ratio))

    # Scale to fit target height while preserving content aspect
    content_w, content_h = img.size
    scale = target_h / content_h
    scaled_w = int(round(content_w * scale))
    scaled_h = target_h

    resized = img.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    offset_x = (target_w - scaled_w) // 2
    canvas.paste(resized, (offset_x, 0), resized)
    return canvas


def process_file(raw_name: str, output_name: str) -> None:
    raw_path = RAW_DIR / raw_name
    if not raw_path.exists():
        # Also check asset dir for already-copied files
        raw_path = ASSET_DIR / raw_name
    if not raw_path.exists():
        print(f"SKIP missing: {raw_name}")
        return

    view = view_key(raw_name.replace("_raw", ""))
    img = Image.open(raw_path)
    img = remove_green_background(img)
    img = crop_to_content(img)
    img = normalize_proportions(img, view)

    out_path = ASSET_DIR / output_name
    img.save(out_path, "PNG", optimize=True)
    print(f"OK {output_name} -> {img.size}")


def main() -> None:
    for raw_name, output_name in OUTPUT_NAMES.items():
        process_file(raw_name, output_name)


if __name__ == "__main__":
    main()
