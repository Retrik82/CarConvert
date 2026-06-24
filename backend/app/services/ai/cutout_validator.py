"""Validate vehicle cutout PNG quality before compositing."""

from __future__ import annotations

import io

from PIL import Image

MIN_OBJECT_AREA_RATIO = 0.03
MIN_ALPHA_VARIANCE = 5


def validate_cutout(image_bytes: bytes) -> tuple[bool, str]:
    """Return (ok, reason)."""
    if not image_bytes or len(image_bytes) < 256:
        return False, "Cutout is empty or too small."

    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            rgba = img.convert("RGBA")
    except Exception as exc:
        return False, f"Invalid cutout image: {exc}"

    width, height = rgba.size
    if width < 32 or height < 32:
        return False, "Cutout dimensions too small."

    alpha = rgba.getchannel("A")
    alpha_data = list(alpha.getdata())
    transparent = sum(1 for a in alpha_data if a < 32)
    opaque = sum(1 for a in alpha_data if a > 200)
    total = len(alpha_data)

    if opaque < total * MIN_OBJECT_AREA_RATIO:
        return False, "Vehicle occupies too little of the cutout."

    if transparent < total * 0.05:
        return False, "Cutout missing transparent background."

    if max(alpha_data) - min(alpha_data) < MIN_ALPHA_VARIANCE and transparent == 0:
        return False, "Cutout has no usable alpha channel."

    return True, "ok"
