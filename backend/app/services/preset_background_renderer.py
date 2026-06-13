"""Render angle-matched studio backgrounds for BMW M4 G82 transparent overlays."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from app.services.scene_layout import CANVAS_HEIGHT, CANVAS_WIDTH, GROUND_Y

WIDTH = CANVAS_WIDTH
HEIGHT = CANVAS_HEIGHT

PRESET_SLUGS = frozenset({"gray-showroom", "auto-workshop"})

HORIZON_Y = int(HEIGHT * 0.58)
PODIUM_TOP_Y = int(HEIGHT * 0.655)


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def _gradient_vertical(
    draw: ImageDraw.ImageDraw,
    rect: tuple[int, int, int, int],
    top: tuple[int, int, int],
    bottom: tuple[int, int, int],
) -> None:
    x0, y0, x1, y1 = rect
    height = max(y1 - y0, 1)
    for y in range(y0, y1):
        t = (y - y0) / height
        color = tuple(_lerp(top[i], bottom[i], t) for i in range(3))
        draw.line([(x0, y), (x1, y)], fill=color)


def _soft_spotlight(image: Image.Image, box: tuple[int, int, int, int], alpha: int = 90) -> Image.Image:
    spot = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    ImageDraw.Draw(spot).ellipse(box, fill=(255, 255, 255, alpha))
    return Image.alpha_composite(image.convert("RGBA"), spot).convert("RGB")


def _draw_floor_shadow(
    image: Image.Image,
    *,
    center_x: int,
    top_y: int,
    width: int,
    height: int,
    opacity: int = 70,
) -> Image.Image:
    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        [center_x - width // 2, top_y, center_x + width // 2, top_y + height],
        fill=(0, 0, 0, opacity),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=14))
    return Image.alpha_composite(image.convert("RGBA"), shadow).convert("RGB")


def _draw_podium(
    image: Image.Image,
    *,
    center_x: int,
    top_y: int = PODIUM_TOP_Y,
    width: int | None = None,
    height: int = int(HEIGHT * 0.04),
    top_color: tuple[int, int, int],
    bottom_color: tuple[int, int, int],
    outline: tuple[int, int, int] = (210, 210, 216),
) -> Image.Image:
    podium_width = width or int(WIDTH * 0.34)
    left = center_x - podium_width // 2
    right = center_x + podium_width // 2
    bottom = top_y + height

    image = _draw_floor_shadow(
        image,
        center_x=center_x,
        top_y=top_y + int(height * 0.35),
        width=int(podium_width * 1.15),
        height=int(HEIGHT * 0.08),
    )

    draw = ImageDraw.Draw(image)
    for i in range(height):
        t = i / max(height - 1, 1)
        color = tuple(_lerp(top_color[j], bottom_color[j], t) for j in range(3))
        draw.line([(left, top_y + i), (right, top_y + i)], fill=color)

    draw.rounded_rectangle(
        [left, top_y, right, bottom],
        radius=max(height // 4, 4),
        outline=outline,
        width=1,
    )
    return image


def _palette(slug: str) -> dict[str, tuple[int, int, int]]:
    if slug == "auto-workshop":
        return {
            "wall_top": (58, 68, 82),
            "wall_bottom": (18, 20, 26),
            "floor_top": (48, 50, 58),
            "floor_bottom": (32, 34, 40),
            "podium_top": (58, 58, 66),
            "podium_bottom": (38, 38, 46),
            "podium_outline": (96, 102, 112),
            "accent": (74, 84, 98),
            "lamp": (255, 248, 232),
        }
    return {
        "wall_top": (232, 232, 236),
        "wall_bottom": (152, 152, 160),
        "floor_top": (208, 208, 214),
        "floor_bottom": (144, 144, 152),
        "podium_top": (228, 228, 234),
        "podium_bottom": (196, 196, 204),
        "podium_outline": (210, 210, 216),
        "accent": (180, 180, 185),
        "lamp": (255, 255, 255),
    }


def _base_canvas(slug: str) -> tuple[Image.Image, ImageDraw.ImageDraw, dict]:
    colors = _palette(slug)
    image = Image.new("RGB", (WIDTH, HEIGHT), colors["accent"])
    draw = ImageDraw.Draw(image)
    _gradient_vertical(draw, (0, 0, WIDTH, HORIZON_Y), colors["wall_top"], colors["wall_bottom"])
    _gradient_vertical(draw, (0, HORIZON_Y, WIDTH, HEIGHT), colors["floor_top"], colors["floor_bottom"])
    draw.line([(0, HORIZON_Y), (WIDTH, HORIZON_Y)], fill=colors["podium_top"], width=2)
    return image, draw, colors


def _workshop_props(image: Image.Image, draw: ImageDraw.ImageDraw, colors: dict) -> Image.Image:
    for i in range(4):
        x = int(WIDTH * (0.14 + i * 0.22))
        draw.rectangle([x - 8, 24, x + 8, int(HEIGHT * 0.11)], fill=(80, 88, 100))
        lamp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        ImageDraw.Draw(lamp).ellipse([x - 28, 36, x + 28, 92], fill=(*colors["lamp"], 110))
        image = Image.alpha_composite(image.convert("RGBA"), lamp).convert("RGB")
        draw = ImageDraw.Draw(image)

    draw.rectangle([int(WIDTH * 0.04), int(HEIGHT * 0.28), int(WIDTH * 0.18), int(HEIGHT * 0.66)], fill=colors["accent"])
    draw.rectangle([int(WIDTH * 0.78), int(HEIGHT * 0.32), int(WIDTH * 0.92), int(HEIGHT * 0.64)], fill=colors["accent"])
    return image


def _render_side(slug: str, *, facing: str) -> Image.Image:
    image, draw, colors = _base_canvas(slug)
    if slug == "auto-workshop":
        image = _workshop_props(image, draw, colors)
        draw = ImageDraw.Draw(image)

    # Long side profile: wall on the opposite side, floor stretches horizontally.
    wall_x = int(WIDTH * 0.08) if facing == "right" else int(WIDTH * 0.92)
    draw.rectangle(
        [wall_x - 40, int(HEIGHT * 0.12), wall_x + 40, HORIZON_Y],
        fill=colors["wall_bottom"],
    )
    image = _soft_spotlight(image, (int(WIDTH * 0.18), 30, int(WIDTH * 0.82), int(HEIGHT * 0.55)))
    draw = ImageDraw.Draw(image)

    return _draw_podium(
        image,
        center_x=WIDTH // 2,
        width=int(WIDTH * 0.52),
        top_color=colors["podium_top"],
        bottom_color=colors["podium_bottom"],
        outline=colors["podium_outline"],
    )


def _render_front_rear(slug: str, *, rear: bool = False) -> Image.Image:
    image, draw, colors = _base_canvas(slug)
    if slug == "auto-workshop":
        image = _workshop_props(image, draw, colors)
        draw = ImageDraw.Draw(image)

    image = _soft_spotlight(image, (WIDTH // 2 - 360, 24, WIDTH // 2 + 360, int(HEIGHT * 0.52)), alpha=95)
    draw = ImageDraw.Draw(image)

    if rear:
        draw.rectangle([int(WIDTH * 0.34), int(HEIGHT * 0.16), int(WIDTH * 0.66), HORIZON_Y], fill=colors["wall_bottom"])

    return _draw_podium(
        image,
        center_x=WIDTH // 2,
        width=int(WIDTH * 0.30),
        top_color=colors["podium_top"],
        bottom_color=colors["podium_bottom"],
        outline=colors["podium_outline"],
    )


def _render_three_quarter(slug: str, *, left: bool) -> Image.Image:
    image, draw, colors = _base_canvas(slug)
    if slug == "auto-workshop":
        image = _workshop_props(image, draw, colors)
        draw = ImageDraw.Draw(image)

    # Perspective floor lines converging toward the car placement.
    vanish_x = int(WIDTH * (0.72 if left else 0.28))
    for offset in (-120, -40, 40, 120):
        draw.line([(vanish_x, HORIZON_Y - 20), (WIDTH // 2 + offset, HEIGHT)], fill=colors["floor_bottom"], width=2)

    corner_x = int(WIDTH * (0.12 if left else 0.88))
    draw.polygon(
        [
            (corner_x, int(HEIGHT * 0.12)),
            (corner_x, HORIZON_Y),
            (WIDTH // 2, HORIZON_Y),
            (WIDTH // 2, int(HEIGHT * 0.2)),
        ],
        fill=colors["wall_bottom"],
    )

    spotlight_center = int(WIDTH * (0.44 if left else 0.56))
    image = _soft_spotlight(
        image,
        (spotlight_center - 300, 24, spotlight_center + 300, int(HEIGHT * 0.54)),
        alpha=90,
    )

    return _draw_podium(
        image,
        center_x=int(WIDTH * (0.46 if left else 0.54)),
        width=int(WIDTH * 0.36),
        top_color=colors["podium_top"],
        bottom_color=colors["podium_bottom"],
        outline=colors["podium_outline"],
    )


def _render_interior(slug: str) -> Image.Image:
    colors = _palette(slug)
    image = Image.new("RGB", (WIDTH, HEIGHT), (24, 26, 30))
    draw = ImageDraw.Draw(image)
    _gradient_vertical(draw, (0, 0, WIDTH, HEIGHT), (42, 46, 54), (18, 20, 24))

    dash_top = int(HEIGHT * 0.42)
    draw.rounded_rectangle(
        [int(WIDTH * 0.08), dash_top, int(WIDTH * 0.92), int(HEIGHT * 0.78)],
        radius=28,
        fill=(34, 38, 46),
    )
    draw.ellipse([int(WIDTH * 0.36), int(HEIGHT * 0.52), int(WIDTH * 0.64), int(HEIGHT * 0.82)], outline=(90, 96, 108), width=3)
    draw.rectangle([int(WIDTH * 0.12), int(HEIGHT * 0.58), int(WIDTH * 0.34), int(HEIGHT * 0.9)], fill=(48, 52, 60))
    draw.rectangle([int(WIDTH * 0.66), int(HEIGHT * 0.58), int(WIDTH * 0.88), int(HEIGHT * 0.9)], fill=(48, 52, 60))
    return _soft_spotlight(image, (WIDTH // 2 - 280, 40, WIDTH // 2 + 280, int(HEIGHT * 0.55)), alpha=70)


_VALID_ANGLES = frozenset({
    "left", "right", "front", "rear", "interior", "three_quarter_left", "three_quarter_right"
})


def render_preset_background(slug: str, path: Path, angle: str | None = None) -> None:
    resolved_angle = angle or (path.stem if path.stem in _VALID_ANGLES else "three_quarter_left")

    if resolved_angle == "interior":
        image = _render_interior(slug)
    elif resolved_angle in {"left", "right"}:
        image = _render_side(slug, facing=resolved_angle)
    elif resolved_angle == "front":
        image = _render_front_rear(slug, rear=False)
    elif resolved_angle == "rear":
        image = _render_front_rear(slug, rear=True)
    elif resolved_angle == "three_quarter_left":
        image = _render_three_quarter(slug, left=True)
    elif resolved_angle == "three_quarter_right":
        image = _render_three_quarter(slug, left=False)
    else:
        image = _render_three_quarter(slug, left=True)

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="JPEG", quality=92, optimize=True)
