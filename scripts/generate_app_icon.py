"""Generate AutoCut app icon assets (1024x1024 RGBA, transparent background)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND_BLUE = (37, 99, 235)
BRAND_PURPLE = (124, 58, 237)
PUPIL = (30, 27, 75)
WHITE = (255, 255, 255)

SIZE = 1024
CX, CY = 512, 528
RIM_R = 268
RIM_W = 38
HUB_R = 58
SPOKE_W = 34
EYE_R = 42
PUPIL_R = 22
HIGHLIGHT_R = 7
HIGHLIGHT_OX, HIGHLIGHT_OY = -9, -10
SPOKE_ANGLES_DEG = (128, 52, -52, -128, 180)


def _lerp_color(t: float) -> tuple[int, int, int]:
    return tuple(int(BRAND_BLUE[i] + (BRAND_PURPLE[i] - BRAND_BLUE[i]) * t) for i in range(3))


def _gradient_color(x: float, y: float) -> tuple[int, int, int]:
    # bottom-left blue -> top-right purple
    t = max(0.0, min(1.0, ((x / SIZE) + (1 - y / SIZE)) / 2))
    return _lerp_color(t)


def _polar(cx: float, cy: float, r: float, deg: float) -> tuple[float, float]:
    rad = math.radians(deg)
    return cx + r * math.cos(rad), cy + r * math.sin(rad)


def _spoke_polygon(cx: float, cy: float, angle_deg: float) -> list[tuple[float, float]]:
    inner = HUB_R * 0.55
    outer = RIM_R - RIM_W * 0.35
    x0, y0 = _polar(cx, cy, inner, angle_deg)
    x1, y1 = _polar(cx, cy, outer, angle_deg)
    perp = math.radians(angle_deg + 90)
    hw0 = SPOKE_W * 0.42
    hw1 = SPOKE_W * 0.22
    return [
        (x0 + hw0 * math.cos(perp), y0 + hw0 * math.sin(perp)),
        (x1 + hw1 * math.cos(perp), y1 + hw1 * math.sin(perp)),
        (x1 - hw1 * math.cos(perp), y1 - hw1 * math.sin(perp)),
        (x0 - hw0 * math.cos(perp), y0 - hw0 * math.sin(perp)),
    ]


def _avg_color(points: list[tuple[float, float]]) -> tuple[int, int, int]:
    ax = sum(p[0] for p in points) / len(points)
    ay = sum(p[1] for p in points) / len(points)
    return _gradient_color(ax, ay)


def _draw_ring(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, width: float) -> None:
    bbox = [cx - r, cy - r, cx + r, cy + r]
    # approximate ring color from rim center point
    color = _gradient_color(cx, cy)
    draw.ellipse(bbox, outline=color + (255,), width=int(round(width)))


def _draw_gradient_circle(
    draw: ImageDraw.ImageDraw, overlay: Image.Image, cx: float, cy: float, r: float
) -> None:
    color = _gradient_color(cx, cy)
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.ellipse(bbox, fill=color + (255,))


def render_icon(pixel_size: int) -> Image.Image:
    scale = pixel_size / SIZE
    img = Image.new("RGBA", (pixel_size, pixel_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def s(v: float) -> float:
        return v * scale

    cx, cy = s(CX), s(CY)
    rim_r, rim_w = s(RIM_R), max(s(RIM_W), 1)
    hub_r = s(HUB_R)
    eye_r, pupil_r = s(EYE_R), s(PUPIL_R)
    hl_r = max(s(HIGHLIGHT_R), 1)
    hl_x, hl_y = cx + s(HIGHLIGHT_OX), cy + s(HIGHLIGHT_OY)

    # Arc segments (upper-left)
    arc_r = s(RIM_R + 52)
    for i in range(7):
        t = i / 6
        deg = 205 + (118 - 205) * t
        length = s(18 + t * 34)
        width = max(s(10 + t * 6), 1)
        x0, y0 = _polar(cx, cy, arc_r, deg)
        x1, y1 = _polar(cx, cy, arc_r + length, deg)
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        color = _gradient_color(mx, my) + (255,)
        draw.line([(x0, y0), (x1, y1)], fill=color, width=int(round(width)))

    # Outer rim
    _draw_ring(draw, cx, cy, rim_r, rim_w)

    # Spokes
    for angle in SPOKE_ANGLES_DEG:
        pts = [(s(x), s(y)) for x, y in _spoke_polygon(CX, CY, angle)]
        color = _avg_color(pts) + (255,)
        draw.polygon(pts, fill=color)

    # Hub
    _draw_gradient_circle(draw, img, cx, cy, hub_r)

    # Eye sclera
    draw.ellipse([cx - eye_r, cy - eye_r, cx + eye_r, cy + eye_r], fill=WHITE + (255,))

    # Pupil
    draw.ellipse([cx - pupil_r, cy - pupil_r, cx + pupil_r, cy + pupil_r], fill=PUPIL + (255,))

    # Highlight
    draw.ellipse([hl_x - hl_r, hl_y - hl_r, hl_x + hl_r, hl_y + hl_r], fill=WHITE + (255,))

    return img


def build_svg_48() -> str:
    vb = 48
    s = vb / SIZE
    cx, cy = CX * s, CY * s
    rim_r, rim_w = RIM_R * s, max(RIM_W * s, 1.6)
    hub_r, eye_r, pupil_r = HUB_R * s, EYE_R * s, PUPIL_R * s
    hl_r = max(HIGHLIGHT_R * s, 0.6)
    hl_x, hl_y = cx + HIGHLIGHT_OX * s, cy + HIGHLIGHT_OY * s

    lines = []
    arc_r = (RIM_R + 52) * s
    for i in range(7):
        t = i / 6
        deg = 205 + (118 - 205) * t
        length = (18 + t * 34) * s
        width = max((10 + t * 6) * s, 0.8)
        x0, y0 = _polar(cx, cy, arc_r, deg)
        x1, y1 = _polar(cx, cy, arc_r + length, deg)
        lines.append(
            f'<line x1="{x0:.3f}" y1="{y0:.3f}" x2="{x1:.3f}" y2="{y1:.3f}" '
            f'stroke="url(#brand)" stroke-width="{width:.2f}" stroke-linecap="round"/>'
        )

    spokes = []
    for a in SPOKE_ANGLES_DEG:
        pts = _spoke_polygon(CX, CY, a)
        d = "M " + " L ".join(f"{x * s:.3f},{y * s:.3f}" for x, y in pts) + " Z"
        spokes.append(f'<path d="{d}" fill="url(#brand)"/>')

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" role="img" aria-label="AutoCut">
  <defs>
    <linearGradient id="brand" x1="0" y1="48" x2="48" y2="0" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2563EB"/>
      <stop offset="100%" stop-color="#7C3AED"/>
    </linearGradient>
  </defs>
  {"".join(lines)}
  <circle cx="{cx:.3f}" cy="{cy:.3f}" r="{rim_r:.3f}" fill="none" stroke="url(#brand)" stroke-width="{rim_w:.2f}"/>
  {"".join(spokes)}
  <circle cx="{cx:.3f}" cy="{cy:.3f}" r="{hub_r:.3f}" fill="url(#brand)"/>
  <circle cx="{cx:.3f}" cy="{cy:.3f}" r="{eye_r:.3f}" fill="#FFFFFF"/>
  <circle cx="{cx:.3f}" cy="{cy:.3f}" r="{pupil_r:.3f}" fill="#1E1B4B"/>
  <circle cx="{hl_x:.3f}" cy="{hl_y:.3f}" r="{hl_r:.3f}" fill="#FFFFFF"/>
</svg>"""


def verify_png(path: Path, expected: int) -> None:
    im = Image.open(path)
    assert im.size == (expected, expected), f"{path}: {im.size}"
    alpha = im.convert("RGBA").split()[3]
    corners = [(0, 0), (expected - 1, 0), (0, expected - 1), (expected - 1, expected - 1)]
    corner_alpha = [alpha.getpixel(c) for c in corners]
    print(f"  {path.relative_to(ROOT)}: {im.size} RGBA, corner alpha={corner_alpha}")


def main() -> None:
    master = render_icon(1024)
    master_path = ROOT / "mobile/assets/branding/app_logo.png"
    master_path.parent.mkdir(parents=True, exist_ok=True)
    master.save(master_path, "PNG")

    render_icon(1024).save(ROOT / "client/public/images/app-logo.png", "PNG")
    render_icon(180).save(ROOT / "client/public/favicon.png", "PNG")
    render_icon(32).save(ROOT / "client/public/favicon-32.png", "PNG")

    favicon_svg = build_svg_48()
    (ROOT / "client/public/favicon.svg").write_text(favicon_svg, encoding="utf-8")
    (ROOT / "mobile/assets/branding/app_logo.svg").write_text(favicon_svg.replace('viewBox="0 0 48 48"', 'viewBox="0 0 48 48"'), encoding="utf-8")

    print("Generated assets:")
    verify_png(master_path, 1024)
    verify_png(ROOT / "client/public/images/app-logo.png", 1024)
    verify_png(ROOT / "client/public/favicon.png", 180)
    verify_png(ROOT / "client/public/favicon-32.png", 32)


if __name__ == "__main__":
    main()
