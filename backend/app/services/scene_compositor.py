"""Compose transparent BMW renders onto studio backgrounds."""

from __future__ import annotations

import logging
from pathlib import Path

from PIL import Image

from app.services.car_asset_service import BUNDLED_CAR_ASSETS, CAR_MODEL
from app.services.scene_layout import (
    CANVAS_HEIGHT,
    CANVAS_WIDTH,
    car_view_for_angle,
    layout_for_angle,
)

logger = logging.getLogger(__name__)

DEFAULT_PREVIEW_PAINT = "white"


def preview_image_path(raw_path: Path) -> Path:
    return raw_path.with_name(f"{raw_path.stem}_preview.jpg")


def car_image_path(angle: str, paint: str = DEFAULT_PREVIEW_PAINT) -> Path | None:
    view = car_view_for_angle(angle)
    if view is None:
        return None
    path = BUNDLED_CAR_ASSETS / f"{view}_{paint}.png"
    return path if path.is_file() else None


def composite_car_on_background(
    background: Image.Image,
    car: Image.Image,
    angle: str,
) -> Image.Image:
    layout = layout_for_angle(angle)
    if layout is None:
        return background.convert("RGB")

    bg = background.convert("RGBA").resize((CANVAS_WIDTH, CANVAS_HEIGHT), Image.Resampling.LANCZOS)
    car_rgba = car.convert("RGBA")

    target_width = max(1, int(CANVAS_WIDTH * layout.car_width_ratio))
    scale = target_width / car_rgba.width
    target_height = max(1, int(car_rgba.height * scale))
    car_scaled = car_rgba.resize((target_width, target_height), Image.Resampling.LANCZOS)

    ground_row = int(target_height * layout.car_ground_ratio)
    center_x = int(CANVAS_WIDTH * layout.center_x_ratio)
    x = center_x - target_width // 2
    y = layout.ground_y - ground_row

    composed = bg.copy()
    composed.paste(car_scaled, (x, y), car_scaled)
    return composed.convert("RGB")


def compose_scene_preview(
    background_path: Path,
    angle: str,
    output_path: Path | None = None,
    *,
    paint: str = DEFAULT_PREVIEW_PAINT,
) -> Path:
    """Bake car onto a background and save a catalog preview JPEG."""
    if angle == "interior" or car_view_for_angle(angle) is None:
        output = output_path or preview_image_path(background_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        Image.open(background_path).convert("RGB").save(output, format="JPEG", quality=92, optimize=True)
        return output

    car_path = car_image_path(angle, paint)
    if car_path is None:
        raise FileNotFoundError(f"Car asset missing for angle {angle}")

    background = Image.open(background_path)
    car = Image.open(car_path)
    composed = composite_car_on_background(background, car, angle)

    output = output_path or preview_image_path(background_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    composed.save(output, format="JPEG", quality=92, optimize=True)
    return output


def ensure_scene_preview(background_path: Path, angle: str) -> Path:
    """Return cached preview path, composing when missing or stale."""
    preview_path = preview_image_path(background_path)
    if (
        preview_path.is_file()
        and background_path.is_file()
        and preview_path.stat().st_mtime >= background_path.stat().st_mtime
    ):
        return preview_path

    return compose_scene_preview(background_path, angle, preview_path)
