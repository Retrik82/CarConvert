import io

from PIL import Image, ImageDraw

from app.utils.image_utils import restore_source_car_on_background


def _solid_png(size: tuple[int, int], color: tuple[int, int, int, int]) -> bytes:
    image = Image.new("RGBA", size, color)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def test_restore_source_car_on_background_uses_source_pixels() -> None:
    source = Image.new("RGB", (200, 100), (240, 240, 240))
    draw = ImageDraw.Draw(source)
    draw.rectangle([60, 20, 140, 80], fill=(200, 30, 30))
    source_buffer = io.BytesIO()
    source.save(source_buffer, format="JPEG")
    source_bytes = source_buffer.getvalue()

    cutout = Image.new("RGBA", (200, 100), (0, 0, 0, 0))
    cutout_draw = ImageDraw.Draw(cutout)
    cutout_draw.rectangle([60, 20, 140, 80], fill=(0, 0, 0, 255))
    cutout_buffer = io.BytesIO()
    cutout.save(cutout_buffer, format="PNG")
    cutout_bytes = cutout_buffer.getvalue()

    background_bytes = _solid_png((200, 100), (20, 80, 160, 255))

    restored_bytes = restore_source_car_on_background(
        source_bytes, cutout_bytes, background_bytes, feather_px=0
    )
    restored = Image.open(io.BytesIO(restored_bytes)).convert("RGB")

    car_pixel = restored.getpixel((100, 50))
    assert car_pixel[1:] == (30, 30)
    assert car_pixel[0] >= 198
    bg_pixel = restored.getpixel((10, 10))
    assert abs(bg_pixel[0] - 20) <= 2
    assert bg_pixel[1:] == (80, 160)
