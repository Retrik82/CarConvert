"""Render preset studio / workshop background JPEGs with a central podium."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

WIDTH = 1280
HEIGHT = 720

PRESET_SLUGS = frozenset({"gray-showroom", "auto-workshop"})


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


def _draw_podium(
    image: Image.Image,
    *,
    center_x: int,
    top_y: int,
    width: int,
    height: int,
    top_color: tuple[int, int, int],
    bottom_color: tuple[int, int, int],
) -> Image.Image:
    left = center_x - width // 2
    right = center_x + width // 2
    bottom = top_y + height

    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [left, top_y + int(height * 0.45), right, bottom + int(height * 0.8)],
        radius=max(height // 3, 4),
        fill=(0, 0, 0, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=12))
    image = Image.alpha_composite(image.convert("RGBA"), shadow).convert("RGB")

    draw = ImageDraw.Draw(image)
    for i in range(height):
        t = i / max(height - 1, 1)
        color = tuple(_lerp(top_color[j], bottom_color[j], t) for j in range(3))
        draw.line([(left, top_y + i), (right, top_y + i)], fill=color)

    draw.rounded_rectangle(
        [left, top_y, right, bottom],
        radius=max(height // 4, 4),
        outline=(210, 210, 216),
        width=1,
    )
    return image


def render_showroom(path: Path) -> None:
    image = Image.new("RGB", (WIDTH, HEIGHT), (200, 200, 206))
    draw = ImageDraw.Draw(image)

    _gradient_vertical(draw, (0, 0, WIDTH, int(HEIGHT * 0.62)), (232, 232, 236), (152, 152, 160))
    _gradient_vertical(draw, (0, int(HEIGHT * 0.62), WIDTH, HEIGHT), (208, 208, 214), (144, 144, 152))

    spot = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    spot_draw = ImageDraw.Draw(spot)
    spot_draw.ellipse([WIDTH // 2 - 420, 40, WIDTH // 2 + 420, 360], fill=(255, 255, 255, 90))
    image = Image.alpha_composite(image.convert("RGBA"), spot).convert("RGB")
    draw = ImageDraw.Draw(image)
    draw.line([(0, int(HEIGHT * 0.62)), (WIDTH, int(HEIGHT * 0.62))], fill=(230, 230, 236), width=2)

    image = _draw_podium(
        image,
        center_x=WIDTH // 2,
        top_y=int(HEIGHT * 0.665),
        width=int(WIDTH * 0.34),
        height=int(HEIGHT * 0.045),
        top_color=(228, 228, 234),
        bottom_color=(196, 196, 204),
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="JPEG", quality=92, optimize=True)


def render_workshop(path: Path) -> None:
    image = Image.new("RGB", (WIDTH, HEIGHT), (26, 30, 36))
    draw = ImageDraw.Draw(image)

    _gradient_vertical(draw, (0, 0, WIDTH, HEIGHT), (58, 68, 82), (18, 20, 26))
    _gradient_vertical(draw, (0, int(HEIGHT * 0.68), WIDTH, HEIGHT), (48, 50, 58), (32, 34, 40))

    for i in range(4):
        x = int(WIDTH * (0.14 + i * 0.22))
        draw.rectangle([x - 8, 24, x + 8, int(HEIGHT * 0.11)], fill=(80, 88, 100))
        lamp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        lamp_draw = ImageDraw.Draw(lamp)
        lamp_draw.ellipse([x - 28, 36, x + 28, 92], fill=(255, 248, 232, 110))
        image = Image.alpha_composite(image.convert("RGBA"), lamp).convert("RGB")
        draw = ImageDraw.Draw(image)

    draw.rectangle([int(WIDTH * 0.04), int(HEIGHT * 0.28), int(WIDTH * 0.18), int(HEIGHT * 0.66)], fill=(74, 84, 98))
    draw.rectangle([int(WIDTH * 0.78), int(HEIGHT * 0.32), int(WIDTH * 0.92), int(HEIGHT * 0.64)], fill=(74, 84, 98))

    image = _draw_podium(
        image,
        center_x=WIDTH // 2,
        top_y=int(HEIGHT * 0.665),
        width=int(WIDTH * 0.34),
        height=int(HEIGHT * 0.045),
        top_color=(58, 58, 66),
        bottom_color=(38, 38, 46),
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="JPEG", quality=92, optimize=True)


def render_preset_background(slug: str, path: Path) -> None:
    if slug == "auto-workshop":
        render_workshop(path)
    else:
        render_showroom(path)
