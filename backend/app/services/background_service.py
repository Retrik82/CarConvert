import base64
import logging
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.background import (
    ANGLE_PROMPT_SUFFIXES,
    VARIANT_ANGLES,
    BackgroundPreset,
    BackgroundVariant,
    UserBackground,
    UserBackgroundVariant,
)
from app.repositories.background_repository import BackgroundRepository
from app.services.ai.background_processor import generate_empty_background, process_with_background

logger = logging.getLogger(__name__)
settings = get_settings()

PRESET_DEFINITIONS = (
    {
        "slug": "gray-showroom",
        "name": "Gray Showroom",
        "description": "Minimalist gray studio with a central podium",
        "prompt_template": (
            "Minimalist empty gray room with smooth concrete walls and floor, "
            "a single round light-gray podium in the center, soft diffused studio lighting, "
            "clean modern interior, subtle shadows, premium product showcase background, "
            "monochromatic gray palette, realistic materials, high detail, photorealistic, "
            "luxury presentation stage, no objects, no people, ultra realistic, 8k render"
        ),
        "sort_order": 1,
        "tint": (180, 180, 185),
    },
    {
        "slug": "auto-workshop",
        "name": "Auto Workshop",
        "description": "Modern professional car service garage",
        "prompt_template": (
            "Modern automotive repair workshop interior, spacious professional car service garage, "
            "clean industrial environment, vehicle lifts, tool cabinets, diagnostic equipment, "
            "organized workspace, concrete floor, bright ceiling lights, realistic automotive "
            "service center background, no cars, no people, photorealistic, high detail, "
            "industrial modern design, ultra realistic, 8k render, depth of field"
        ),
        "sort_order": 2,
        "tint": (120, 130, 145),
    },
)


def backgrounds_root() -> Path:
    path = Path(settings.upload_dir) / "backgrounds"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _write_placeholder_image(path: Path, *, title: str, subtitle: str, tint: tuple[int, int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return

    width, height = 1280, 720
    image = Image.new("RGB", (width, height), tint)
    draw = ImageDraw.Draw(image)

    for y in range(height):
        factor = y / height
        color = tuple(int(c * (0.75 + 0.25 * factor)) for c in tint)
        draw.line([(0, y), (width, y)], fill=color)

    overlay = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rectangle([80, height // 2 - 60, width - 80, height // 2 + 60], fill=(255, 255, 255, 40))
    image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(image)
    draw.text((100, height // 2 - 40), title, fill=(255, 255, 255))
    draw.text((100, height // 2 + 4), subtitle, fill=(230, 230, 230))

    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=88)
    path.write_bytes(buffer.getvalue())


def _save_image_bytes(path: Path, image_bytes: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(image_bytes)


def _image_to_data_url(path: Path) -> str | None:
    if not path.exists():
        return None
    suffix = path.suffix.lower()
    mime = {"jpg": "image/jpeg", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png"}.get(
        suffix, "image/jpeg"
    )
    encoded = base64.b64encode(path.read_bytes()).decode("utf-8")
    return f"data:{mime};base64,{encoded}"


class BackgroundService:
    def __init__(self, db: AsyncSession) -> None:
        self._repo = BackgroundRepository(db)
        self._db = db

    async def list_catalog(self, user_id: str) -> tuple[list[BackgroundPreset], list[UserBackground]]:
        presets = await self._repo.list_active_presets()
        custom = await self._repo.list_user_backgrounds(user_id)
        return presets, custom

    async def get_preset(self, preset_id: str) -> BackgroundPreset | None:
        return await self._repo.get_preset(preset_id)

    async def get_user_background(self, background_id: str, user_id: str) -> UserBackground | None:
        return await self._repo.get_user_background(background_id, user_id)

    async def resolve_variant_for_job(
        self,
        *,
        preset_id: str | None,
        preset_variant_id: str | None,
        user_background_id: str | None,
        user_variant_id: str | None,
        user_id: str,
        angle: str | None = None,
    ) -> tuple[str, str | None]:
        selected_angle = angle or "three_quarter_left"

        if user_background_id:
            background = await self._repo.get_user_background(user_background_id, user_id)
            if not background:
                raise ValueError("Custom background not found.")
            variant = None
            if user_variant_id:
                variant = await self._repo.get_user_variant(user_variant_id)
            if variant is None or variant.background_id != background.id:
                variant = await self._repo.get_user_background_variant(background.id, selected_angle)
            if variant is None:
                raise ValueError("Background variant not found.")
            prompt = f"{background.prompt} {variant.prompt_suffix}".strip()
            reference = _image_to_data_url(Path(variant.image_path)) if variant.image_path else None
            return prompt, reference

        if preset_id:
            preset = await self._repo.get_preset(preset_id)
            if not preset:
                raise ValueError("Background preset not found.")
            variant = None
            if preset_variant_id:
                variant = await self._repo.get_variant(preset_variant_id)
            if variant is None or variant.preset_id != preset.id:
                variant = await self._repo.get_preset_variant(preset.id, selected_angle)
            if variant is None:
                raise ValueError("Background variant not found.")
            prompt = f"{preset.prompt_template} {variant.prompt_suffix}".strip()
            reference = _image_to_data_url(Path(variant.image_path)) if variant.image_path else None
            return prompt, reference

        from app.services.ai.desert_processor import DESERT_USER_PROMPT

        return DESERT_USER_PROMPT, None

    async def create_user_background(
        self,
        user_id: str,
        name: str,
        prompt: str,
        api_key: str,
    ) -> UserBackground:
        background = UserBackground(user_id=user_id, name=name.strip(), prompt=prompt.strip())
        await self._repo.add_user_background(background)

        root = backgrounds_root() / "users" / user_id / background.id
        preview_variant: UserBackgroundVariant | None = None

        for angle in VARIANT_ANGLES:
            suffix = ANGLE_PROMPT_SUFFIXES[angle]
            variant = UserBackgroundVariant(
                background_id=background.id,
                angle=angle,
                prompt_suffix=suffix,
            )
            await self._repo.add_user_variant(variant)

            image_path = root / f"{angle}.jpg"
            try:
                image_b64, mime = await generate_empty_background(
                    f"{prompt.strip()} {suffix}",
                    api_key,
                )
                ext = ".png" if mime == "image/png" else ".jpg"
                image_path = root / f"{angle}{ext}"
                _save_image_bytes(image_path, base64.b64decode(image_b64))
                variant.image_path = str(image_path)
                if preview_variant is None or angle == "three_quarter_left":
                    preview_variant = variant
            except Exception as exc:
                logger.warning("Failed to generate custom background variant %s: %s", angle, exc)
                _write_placeholder_image(
                    image_path,
                    title=name.strip(),
                    subtitle=angle.replace("_", " ").title(),
                    tint=(90, 90, 95),
                )
                variant.image_path = str(image_path)
                if preview_variant is None:
                    preview_variant = variant

        if preview_variant:
            background.preview_variant_id = preview_variant.id

        await self._db.flush()
        return background

    async def seed_presets(self) -> None:
        for definition in PRESET_DEFINITIONS:
            existing = await self._repo.get_preset_by_slug(definition["slug"])
            if existing:
                continue

            preset = BackgroundPreset(
                slug=definition["slug"],
                name=definition["name"],
                description=definition["description"],
                prompt_template=definition["prompt_template"],
                sort_order=definition["sort_order"],
            )
            await self._repo.add_preset(preset)

            preview_variant: BackgroundVariant | None = None
            for angle in VARIANT_ANGLES:
                variant = BackgroundVariant(
                    preset_id=preset.id,
                    angle=angle,
                    prompt_suffix=ANGLE_PROMPT_SUFFIXES[angle],
                )
                await self._repo.add_variant(variant)

                image_path = backgrounds_root() / "presets" / preset.slug / f"{angle}.jpg"
                _write_placeholder_image(
                    image_path,
                    title=definition["name"],
                    subtitle=angle.replace("_", " ").title(),
                    tint=definition["tint"],
                )
                variant.image_path = str(image_path)
                if preview_variant is None or angle == "three_quarter_left":
                    preview_variant = variant

            if preview_variant:
                preset.preview_variant_id = preview_variant.id
            await self._repo.update_preset(preset)

    async def get_variant_image_path(self, variant_id: str, user_id: str) -> Path | None:
        variant = await self._repo.get_variant(variant_id)
        if variant and variant.image_path:
            path = Path(variant.image_path)
            if path.exists():
                return path

        user_variant = await self._repo.get_user_variant(variant_id)
        if user_variant:
            background = await self._repo.get_user_background(user_variant.background_id, user_id)
            if background and user_variant.image_path:
                path = Path(user_variant.image_path)
                if path.exists():
                    return path
        return None


async def process_photo_with_background(
    source_data_url: str,
    background_prompt: str,
    reference_data_url: str | None,
    api_key: str,
) -> tuple[str, str]:
    return await process_with_background(
        source_data_url,
        background_prompt,
        reference_data_url,
        api_key,
    )
