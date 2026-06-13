"""Compose BMW M4 renders into studio scenes — primary catalog & AI reference assets."""

from __future__ import annotations

import logging
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from app.services.car_asset_service import BUNDLED_CAR_ASSETS
from app.services.scene_layout import (
    CANVAS_HEIGHT,
    CANVAS_WIDTH,
    MARGIN_SIDE_RATIO,
    MARGIN_TOP_RATIO,
    car_view_for_angle,
    layout_for_angle,
)

logger = logging.getLogger(__name__)

DEFAULT_SCENE_PAINT = "white"
ALPHA_CUTOFF = 24


def room_image_path(scene_path: Path) -> Path:
    return scene_path.with_name(f"{scene_path.stem}_room.jpg")


def car_image_path(angle: str, paint: str = DEFAULT_SCENE_PAINT) -> Path | None:
    view = car_view_for_angle(angle)
    if view is None:
        return None
    path = BUNDLED_CAR_ASSETS / f"{view}_{paint}.png"
    return path if path.is_file() else None


def _content_bbox(car: Image.Image) -> tuple[int, int, int, int]:
    alpha = car.convert("RGBA").split()[3]
    return alpha.point(lambda value: 255 if value > ALPHA_CUTOFF else 0).getbbox() or (0, 0, car.width, car.height)


def _strip_baked_shadow(car: Image.Image) -> Image.Image:
    """Remove the PNG's baked-in floor shadow — compositor draws its own."""
    car = car.convert("RGBA")
    pixels = car.load()
    width, height = car.size
    bbox = _content_bbox(car)
    if not bbox:
        return car

    shadow_zone_top = bbox[1] + int((bbox[3] - bbox[1]) * 0.72)
    for y in range(shadow_zone_top, height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            brightness = (r + g + b) / 3
            if brightness < 95 or a < 210:
                pixels[x, y] = (0, 0, 0, 0)
    return car


def _clean_car_alpha(car: Image.Image) -> Image.Image:
    car = _strip_baked_shadow(car)
    pixels = car.load()
    width, height = car.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < ALPHA_CUTOFF:
                pixels[x, y] = (0, 0, 0, 0)
            elif a < 180:
                pixels[x, y] = (r, g, b, int(a * 0.5))
    return car


def _fit_car_scale(car: Image.Image, layout) -> float:
    bbox = _content_bbox(car)
    content_w = max(bbox[2] - bbox[0], 1)
    content_h = max(bbox[3] - bbox[1], 1)
    ground_offset = bbox[3]  # distance from image top to ground row inside PNG

    max_width = int(CANVAS_WIDTH * layout.max_width_ratio)
    max_side = int(CANVAS_WIDTH * (0.5 - MARGIN_SIDE_RATIO))
    allowed_width = min(max_width, max_side * 2)

    top_limit = int(CANVAS_HEIGHT * MARGIN_TOP_RATIO)
    allowed_height = max(1, layout.ground_y - top_limit)

    scale_w = allowed_width / content_w
    scale_h = allowed_height / content_h
    return min(scale_w, scale_h)


def _draw_contact_shadow(
    canvas: Image.Image,
    *,
    center_x: int,
    ground_y: int,
    width: int,
) -> Image.Image:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.ellipse(
        [
            center_x - width // 2,
            ground_y - int(CANVAS_HEIGHT * 0.018),
            center_x + width // 2,
            ground_y + int(CANVAS_HEIGHT * 0.05),
        ],
        fill=(0, 0, 0, 48),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=16))
    return Image.alpha_composite(canvas, shadow)


def composite_car_on_room(
    room: Image.Image,
    car: Image.Image,
    angle: str,
) -> Image.Image:
    layout = layout_for_angle(angle)
    if layout is None:
        return room.convert("RGB")

    canvas = room.convert("RGBA").resize((CANVAS_WIDTH, CANVAS_HEIGHT), Image.Resampling.LANCZOS)
    car_rgba = _clean_car_alpha(car)
    bbox = _content_bbox(car_rgba)

    scale = _fit_car_scale(car_rgba, layout)
    target_width = max(1, int(car_rgba.width * scale))
    target_height = max(1, int(car_rgba.height * scale))
    car_scaled = car_rgba.resize((target_width, target_height), Image.Resampling.LANCZOS)

    scaled_bbox = _content_bbox(car_scaled)
    ground_row = scaled_bbox[3]
    top_row = scaled_bbox[1]

    center_x = int(CANVAS_WIDTH * layout.center_x_ratio)
    x = center_x - (scaled_bbox[0] + scaled_bbox[2]) // 2
    y = layout.ground_y - ground_row

    # Clamp so the roof is never clipped.
    top_limit = int(CANVAS_HEIGHT * MARGIN_TOP_RATIO)
    if y + top_row < top_limit:
        y = top_limit - top_row

    shadow_width = int((scaled_bbox[2] - scaled_bbox[0]) * 0.92)
    canvas = _draw_contact_shadow(canvas, center_x=center_x, ground_y=layout.ground_y, width=shadow_width)

    composed = canvas.copy()
    composed.paste(car_scaled, (x, y), car_scaled)
    return composed.convert("RGB")


def compose_scene_from_room(
    room_path: Path,
    angle: str,
    scene_path: Path,
    *,
    paint: str = DEFAULT_SCENE_PAINT,
) -> Path:
    scene_path.parent.mkdir(parents=True, exist_ok=True)

    if angle == "interior" or car_view_for_angle(angle) is None:
        Image.open(room_path).convert("RGB").save(scene_path, format="JPEG", quality=92, optimize=True)
        return scene_path

    car_path = car_image_path(angle, paint)
    if car_path is None:
        raise FileNotFoundError(f"Car asset missing for angle {angle}")

    composed = composite_car_on_room(Image.open(room_path), Image.open(car_path), angle)
    composed.save(scene_path, format="JPEG", quality=92, optimize=True)
    return scene_path


def build_preset_scene(slug: str, angle: str, scene_path: Path) -> Path:
    from app.services.preset_background_renderer import render_preset_background

    scene_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_room = Path(tmp) / "room.jpg"
        render_preset_background(slug, tmp_room, angle)
        compose_scene_from_room(tmp_room, angle, scene_path)

    return scene_path


def build_scene_from_room_bytes(room_bytes: bytes, angle: str, scene_path: Path) -> Path:
    scene_path.parent.mkdir(parents=True, exist_ok=True)
    room_path = room_image_path(scene_path)
    room_path.write_bytes(room_bytes)
    try:
        return compose_scene_from_room(room_path, angle, scene_path)
    finally:
        if room_path.exists():
            try:
                room_path.unlink()
            except FileNotFoundError:
                pass
