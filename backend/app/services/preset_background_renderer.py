"""Clean photorealistic-style studio rooms for BMW M4 composed scenes."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from app.services.scene_layout import CANVAS_HEIGHT, CANVAS_WIDTH, GROUND_Y

WIDTH = CANVAS_WIDTH
HEIGHT = CANVAS_HEIGHT

PRESET_SLUGS = frozenset({"gray-showroom", "auto-workshop"})

HORIZON_Y = int(HEIGHT * 0.60)
FLOOR_LINE_Y = GROUND_Y


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


def _soft_spotlight(image: Image.Image, box: tuple[int, int, int, int], alpha: int = 70) -> Image.Image:
    spot = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    ImageDraw.Draw(spot).ellipse(box, fill=(255, 255, 255, alpha))
    return Image.alpha_composite(image.convert("RGBA"), spot).convert("RGB")


def _floor_disc(image: Image.Image, *, center_x: int, colors: dict, width_ratio: float = 0.42) -> Image.Image:
    """Subtle circular floor patch — no raised podium block."""
    disc_w = int(WIDTH * width_ratio)
    disc_h = int(HEIGHT * 0.07)
    top = FLOOR_LINE_Y - disc_h // 2

    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.ellipse(
        [center_x - disc_w // 2, top, center_x + disc_w // 2, top + disc_h],
        fill=(*colors["disc"], 255),
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=6))
    return Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")


def _palette(slug: str) -> dict[str, tuple[int, int, int]]:
    if slug == "auto-workshop":
        return {
            "wall_top": (72, 78, 88),
            "wall_bottom": (34, 38, 46),
            "floor_near": (56, 60, 68),
            "floor_far": (40, 44, 52),
            "disc": (64, 68, 76),
            "accent": (88, 96, 108),
            "lamp": (255, 244, 220),
        }
    return {
        "wall_top": (236, 236, 240),
        "wall_bottom": (168, 170, 178),
        "floor_near": (214, 216, 222),
        "floor_far": (176, 178, 186),
        "disc": (226, 228, 234),
        "accent": (196, 198, 206),
        "lamp": (255, 255, 255),
    }


def _base_studio(slug: str) -> tuple[Image.Image, ImageDraw.ImageDraw, dict]:
    colors = _palette(slug)
    image = Image.new("RGB", (WIDTH, HEIGHT), colors["accent"])
    draw = ImageDraw.Draw(image)
    _gradient_vertical(draw, (0, 0, WIDTH, HORIZON_Y), colors["wall_top"], colors["wall_bottom"])
    _gradient_vertical(draw, (0, HORIZON_Y, WIDTH, HEIGHT), colors["floor_far"], colors["floor_near"])
    draw.line([(0, HORIZON_Y), (WIDTH, HORIZON_Y)], fill=colors["disc"], width=1)
    return image, draw, colors


def _workshop_ceiling_lights(image: Image.Image, colors: dict) -> Image.Image:
    for i in range(3):
        x = int(WIDTH * (0.25 + i * 0.25))
        lamp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        ImageDraw.Draw(lamp).ellipse([x - 70, 32, x + 70, 88], fill=(*colors["lamp"], 45))
        image = Image.alpha_composite(image.convert("RGBA"), lamp).convert("RGB")
    return image


def _render_side(slug: str) -> Image.Image:
    image, _draw, colors = _base_studio(slug)
    if slug == "auto-workshop":
        image = _workshop_ceiling_lights(image, colors)

    image = _soft_spotlight(image, (int(WIDTH * 0.15), 20, int(WIDTH * 0.85), int(HEIGHT * 0.55)), alpha=55)
    return _floor_disc(image, center_x=WIDTH // 2, colors=colors, width_ratio=0.50)


def _render_front_rear(slug: str) -> Image.Image:
    image, draw, colors = _base_studio(slug)
    if slug == "auto-workshop":
        image = _workshop_ceiling_lights(image, colors)

    # Subtle back wall panel
    draw.rectangle([int(WIDTH * 0.22), int(HEIGHT * 0.14), int(WIDTH * 0.78), HORIZON_Y], fill=colors["wall_bottom"])
    image = _soft_spotlight(image, (WIDTH // 2 - 340, 16, WIDTH // 2 + 340, int(HEIGHT * 0.50)), alpha=65)
    return _floor_disc(image, center_x=WIDTH // 2, colors=colors, width_ratio=0.34)


def _render_three_quarter(slug: str, *, left: bool) -> Image.Image:
    image, _draw, colors = _base_studio(slug)
    if slug == "auto-workshop":
        image = _workshop_ceiling_lights(image, colors)

    spot_x = int(WIDTH * (0.44 if left else 0.56))
    image = _soft_spotlight(
        image,
        (spot_x - 280, 18, spot_x + 280, int(HEIGHT * 0.52)),
        alpha=48,
    )
    disc_x = int(WIDTH * (0.48 if left else 0.52))
    return _floor_disc(image, center_x=disc_x, colors=colors, width_ratio=0.38)


def _render_interior(slug: str) -> Image.Image:
    colors = _palette(slug)
    image = Image.new("RGB", (WIDTH, HEIGHT), (28, 30, 36))
    draw = ImageDraw.Draw(image)
    _gradient_vertical(draw, (0, 0, WIDTH, HEIGHT), (50, 54, 62), (20, 22, 28))

    draw.rounded_rectangle(
        [int(WIDTH * 0.10), int(HEIGHT * 0.40), int(WIDTH * 0.90), int(HEIGHT * 0.76)],
        radius=24,
        fill=(38, 42, 50),
    )
    draw.ellipse(
        [int(WIDTH * 0.38), int(HEIGHT * 0.54), int(WIDTH * 0.62), int(HEIGHT * 0.80)],
        outline=(100, 106, 118),
        width=3,
    )
    return _soft_spotlight(image, (WIDTH // 2 - 260, 36, WIDTH // 2 + 260, int(HEIGHT * 0.52)), alpha=55)


_VALID_ANGLES = frozenset({
    "left", "right", "front", "rear", "interior", "three_quarter_left", "three_quarter_right"
})


def render_preset_background(slug: str, path: Path, angle: str | None = None) -> None:
    resolved_angle = angle or (path.stem if path.stem in _VALID_ANGLES else "three_quarter_left")

    if resolved_angle == "interior":
        image = _render_interior(slug)
    elif resolved_angle in {"left", "right"}:
        image = _render_side(slug)
    elif resolved_angle == "front":
        image = _render_front_rear(slug)
    elif resolved_angle == "rear":
        image = _render_front_rear(slug)
    elif resolved_angle == "three_quarter_left":
        image = _render_three_quarter(slug, left=True)
    elif resolved_angle == "three_quarter_right":
        image = _render_three_quarter(slug, left=False)
    else:
        image = _render_three_quarter(slug, left=True)

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="JPEG", quality=93, optimize=True)
