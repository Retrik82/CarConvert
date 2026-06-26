import asyncio
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
from app.services.ai.background_processor import generate_full_scene
from app.services.user_car_pipeline import ResolvedBackground
from app.utils.image_utils import sanitize_inplace_background_prompt

logger = logging.getLogger(__name__)
settings = get_settings()

PRESET_DEFINITIONS = (
    {
        "slug": "gray-showroom",
        "name": "Gray Showroom",
        "description": "Minimalist gray studio with a central podium",
        "environment_template": (
            "Minimalist luxury gray automotive showroom studio. Smooth gray concrete walls and floor, "
            "soft diffused ceiling lighting, monochromatic gray palette, premium presentation space. "
            "A single round light-gray podium/platform under the vehicle. "
            "Professional automotive studio photography with soft natural shadows."
        ),
        "prompt_template": (
            "Minimalist luxury gray automotive showroom studio. Smooth concrete walls and floor, "
            "soft diffused ceiling lighting, monochromatic gray palette, premium presentation space. "
            "A single round light-gray podium/platform centered in frame. "
            "Empty environment ready for a vehicle — no car, no people, no text. "
            "Photorealistic, landscape 16:9, professional automotive photography lighting."
        ),
        "sort_order": 1,
        "tint": (180, 180, 185),
    },
    {
        "slug": "auto-workshop",
        "name": "Auto Workshop",
        "description": "Modern professional car service garage",
        "environment_template": (
            "Modern professional automotive service garage. Clean industrial interior, concrete floor, "
            "bright ceiling workshop lights, tool cabinets and vehicle lift in the background, "
            "organized workspace. A low circular platform/podium under the vehicle. "
            "Professional workshop photography with natural shadows."
        ),
        "prompt_template": (
            "Modern professional automotive service garage. Clean industrial interior, concrete floor, "
            "bright ceiling workshop lights, tool cabinets and vehicle lift in the background, "
            "organized workspace. A low circular platform/podium where a car would be displayed. "
            "Empty environment — no vehicle, no people, no text. "
            "Photorealistic, landscape 16:9, professional workshop photography."
        ),
        "sort_order": 2,
        "tint": (120, 130, 145),
    },
)

PRESET_ENVIRONMENT_BY_SLUG = {
    definition["slug"]: definition["environment_template"] for definition in PRESET_DEFINITIONS
}


def inplace_environment_for_preset(slug: str, fallback_template: str) -> str:
    """Return full studio environment prompt for in-place editing."""
    return PRESET_ENVIRONMENT_BY_SLUG.get(slug, sanitize_inplace_background_prompt(fallback_template))


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

    async def get_preset_by_slug(self, slug: str) -> BackgroundPreset | None:
        return await self._repo.get_preset_by_slug(slug)

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
    ) -> ResolvedBackground:
        selected_angle = angle or "three_quarter_left"

        if user_background_id:
            background = await self._repo.get_user_background(user_background_id, user_id)
            if not background:
                raise ValueError("Custom background not found.")
            prompt = sanitize_inplace_background_prompt(background.prompt.strip())
            scene_path: str | None = None
            for variant in background.variants:
                if variant.angle == selected_angle and variant.image_path:
                    path = Path(variant.image_path)
                    if path.is_file():
                        scene_path = str(path)
                        break
            return ResolvedBackground(
                prompt=prompt,
                angle=selected_angle,
                user_background_id=background.id,
                scene_image_path=scene_path,
            )

        preset = None
        if preset_id:
            preset = await self._repo.get_preset(preset_id)
            if not preset:
                raise ValueError("Background preset not found.")

        if preset is None:
            presets = await self._repo.list_active_presets()
            if not presets:
                raise ValueError("No background presets configured.")
            preset = presets[0]

        prompt = inplace_environment_for_preset(preset.slug, preset.prompt_template).strip()
        from app.services.background_asset_service import ensure_preset_scene

        scene_path = ensure_preset_scene(preset.slug, selected_angle)
        return ResolvedBackground(
            prompt=prompt,
            angle=selected_angle,
            preset_slug=preset.slug,
            scene_image_path=str(scene_path),
        )

    async def create_user_background(
        self,
        user_id: str,
        name: str,
        prompt: str,
        api_key: str,
    ) -> UserBackground:
        from app.services.ai_scene_generator import generate_custom_scene_ai

        background = UserBackground(user_id=user_id, name=name.strip(), prompt=prompt.strip())
        await self._repo.add_user_background(background)

        root = backgrounds_root() / "users" / user_id / background.id
        variants_by_angle: dict[str, UserBackgroundVariant] = {}

        for angle in VARIANT_ANGLES:
            variant = UserBackgroundVariant(
                background_id=background.id,
                angle=angle,
                prompt_suffix=ANGLE_PROMPT_SUFFIXES[angle],
            )
            await self._repo.add_user_variant(variant)
            variants_by_angle[angle] = variant

        async def generate_angle(angle: str) -> tuple[str, Path | None, Exception | None]:
            scene_path = root / f"{angle}.jpg"
            last_error: Exception | None = None
            for attempt in range(2):
                try:
                    await generate_custom_scene_ai(prompt.strip(), angle, scene_path, api_key)
                    return angle, scene_path, None
                except Exception as exc:
                    last_error = exc
                    logger.warning(
                        "Custom scene attempt %s for %s failed: %s",
                        attempt + 1,
                        angle,
                        exc,
                    )
                    if attempt == 0:
                        await asyncio.sleep(1.5 * (attempt + 1))
            return angle, None, last_error

        semaphore = asyncio.Semaphore(2)

        async def generate_angle_limited(angle: str) -> tuple[str, Path | None, Exception | None]:
            async with semaphore:
                return await generate_angle(angle)

        results = await asyncio.gather(*(generate_angle_limited(angle) for angle in VARIANT_ANGLES))

        preview_variant: UserBackgroundVariant | None = None
        failed_angles: list[str] = []
        for angle, scene_path, error in results:
            if error is not None or scene_path is None:
                failed_angles.append(angle)
                continue
            variant = variants_by_angle[angle]
            variant.image_path = str(scene_path)
            if preview_variant is None or angle == "three_quarter_left":
                preview_variant = variant

        if preview_variant is None or not preview_variant.image_path:
            raise RuntimeError(
                "Background generation failed for all angles. "
                "Check OPENROUTER_API_KEY, model availability, and provider limits."
            )

        preview_path = Path(preview_variant.image_path)
        for angle in failed_angles:
            if not preview_path.is_file():
                break
            fallback_path = root / f"{angle}.jpg"
            try:
                fallback_path.parent.mkdir(parents=True, exist_ok=True)
                fallback_path.write_bytes(preview_path.read_bytes())
                variants_by_angle[angle].image_path = str(fallback_path)
            except Exception as exc:
                logger.warning(
                    "Failed to apply fallback scene for angle=%s background=%s: %s",
                    angle,
                    background.id,
                    exc,
                )

        if failed_angles:
            logger.warning(
                "Custom background %s generated with partial AI failures; fallback applied for angles: %s",
                background.id,
                ", ".join(failed_angles),
            )

        background.preview_variant_id = preview_variant.id

        await self._db.flush()
        return background

    async def seed_presets(self) -> None:
        from app.services.background_asset_service import ensure_preset_scene

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

                scene_path = ensure_preset_scene(preset.slug, angle)
                variant.image_path = str(scene_path)
                if preview_variant is None or angle == "three_quarter_left":
                    preview_variant = variant

            if preview_variant:
                preset.preview_variant_id = preview_variant.id
            await self._repo.update_preset(preset)

    async def sync_preset_images(self) -> None:
        """Ensure preset composed scenes on the server match bundled assets."""
        from app.services.background_asset_service import ensure_preset_scene, seed_preset_scenes
        from app.services.preset_background_renderer import PRESET_SLUGS

        seed_preset_scenes()

        for slug in PRESET_SLUGS:
            for angle in VARIANT_ANGLES:
                ensure_preset_scene(slug, angle)

        presets = await self._repo.list_active_presets()
        for preset in presets:
            if preset.slug not in PRESET_SLUGS:
                continue
            for variant in preset.variants:
                scene_path = ensure_preset_scene(preset.slug, variant.angle)
                variant.image_path = str(scene_path)
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
    resolved: ResolvedBackground,
    api_key: str,
    *,
    job_dir: Path | None = None,
    recomposite: bool = False,
) -> tuple[str, str]:
    from app.services.user_car_pipeline import process_recomposite_photo, process_user_car_photo

    if recomposite:
        return await process_recomposite_photo(source_data_url, resolved, api_key, job_dir=job_dir)
    return await process_user_car_photo(source_data_url, resolved, api_key, job_dir=job_dir)
