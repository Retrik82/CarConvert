import base64
import io
from typing import Tuple

from PIL import Image

MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024
ALLOWED_MIME_TYPES = {
    "image/jpeg": "jpeg",
    "image/png": "png",
    "image/webp": "webp",
}
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}


def validate_image_upload(filename: str, content_type: str, image_bytes: bytes) -> None:
    if not filename:
        raise ValueError("Image filename is required.")

    extension = filename.split(".")[-1].lower() if "." in filename else ""
    if extension not in ALLOWED_EXTENSIONS:
        raise ValueError("Unsupported file extension. Use jpg, jpeg, png, or webp.")

    if content_type not in ALLOWED_MIME_TYPES:
        raise ValueError("Unsupported content type. Use JPG, PNG, or WEBP.")

    if len(image_bytes) == 0:
        raise ValueError("Uploaded file is empty.")

    if len(image_bytes) > MAX_FILE_SIZE_BYTES:
        raise ValueError("File exceeds 10MB limit.")

    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            img.verify()
    except Exception as exc:
        raise ValueError("Uploaded file is not a valid image.") from exc


def to_data_url(image_bytes: bytes, mime_type: str) -> str:
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    return f"data:{mime_type};base64,{encoded}"


def parse_data_url(data_url: str) -> Tuple[str, str]:
    if not data_url.startswith("data:") or ";base64," not in data_url:
        raise ValueError("Invalid data URL format.")

    header, payload = data_url.split(",", 1)
    mime_type = header.replace("data:", "").replace(";base64", "")
    return mime_type, payload


# Must match mobile/lib/overlays/frame_guide_painter.dart guide rect ratios.
FRAME_CROP_LEFT = 0.08
FRAME_CROP_TOP = 0.22
FRAME_CROP_WIDTH = 0.84
FRAME_CROP_HEIGHT = 0.48


def crop_to_frame_guide(image_bytes: bytes) -> bytes:
    """Crop image to the on-screen guide frame (car composition area)."""
    with Image.open(io.BytesIO(image_bytes)) as img:
        img = img.convert("RGB")
        width, height = img.size
        left = int(width * FRAME_CROP_LEFT)
        top = int(height * FRAME_CROP_TOP)
        crop_width = max(1, int(width * FRAME_CROP_WIDTH))
        crop_height = max(1, int(height * FRAME_CROP_HEIGHT))
        right = min(width, left + crop_width)
        bottom = min(height, top + crop_height)
        cropped = img.crop((left, top, right, bottom))
        buffer = io.BytesIO()
        cropped.save(buffer, format="JPEG", quality=92, optimize=True)
        return buffer.getvalue()


def resize_for_preview(image_bytes: bytes, max_edge: int = 512) -> tuple[bytes, str]:
    with Image.open(io.BytesIO(image_bytes)) as img:
        img = img.convert("RGB")
        img.thumbnail((max_edge, max_edge), Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        img.save(buffer, format="JPEG", quality=70, optimize=True)
        return buffer.getvalue(), "image/jpeg"


def read_file_as_base64(path: str) -> tuple[str, str]:
    import pathlib

    data = pathlib.Path(path).read_bytes()
    suffix = pathlib.Path(path).suffix.lower()
    mime = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(suffix, "image/jpeg")
    return base64.b64encode(data).decode("utf-8"), mime
