from app.db.models.background import ANGLE_PROMPT_SUFFIXES
from app.services.ai.prompt_builder import build_background_environment_prompt, build_inplace_edit_user_text
from app.services.ai.vehicle_descriptor import format_vehicle_identity
from app.services.user_car_pipeline import ResolvedBackground, build_background_replace_prompt
from app.utils.image_utils import sanitize_inplace_background_prompt


def test_background_replace_prompt_preserves_camera_angle() -> None:
    resolved = ResolvedBackground(
        prompt="Minimalist luxury gray automotive showroom studio.",
        angle="three_quarter_left",
        preset_slug="gray-showroom",
    )
    prompt = build_background_replace_prompt(resolved)

    assert "Keep the vehicle and original camera angle" in prompt
    for suffix in ANGLE_PROMPT_SUFFIXES.values():
        assert suffix not in prompt


def test_background_replace_prompt_strips_scene_generation_phrases() -> None:
    resolved = ResolvedBackground(
        prompt=(
            "Minimalist luxury gray automotive showroom studio. "
            "Empty environment ready for a vehicle — no car, no people, no text. "
            "Photorealistic, landscape 16:9."
        ),
        angle="three_quarter_left",
    )
    prompt = build_background_replace_prompt(resolved)

    assert "no car" not in prompt.lower()
    assert "16:9" not in prompt
    assert "empty environment" not in prompt.lower()


def test_sanitize_inplace_background_prompt() -> None:
    raw = (
        "Modern garage. A low circular platform/podium where a car would be displayed. "
        "Empty environment — no vehicle, no people. Landscape 16:9."
    )
    cleaned = sanitize_inplace_background_prompt(raw)

    assert "podium" not in cleaned.lower()
    assert "no vehicle" not in cleaned.lower()
    assert "16:9" not in cleaned
    assert cleaned.startswith("Modern garage.")


def test_background_replace_prompt_interior() -> None:
    resolved = ResolvedBackground(
        prompt="Warm leather interior studio.",
        angle="interior",
    )
    prompt = build_background_replace_prompt(resolved)

    assert "cabin interior" in prompt
    assert "Camera:" not in prompt


def test_legacy_edit_user_prompt_sanitizes_and_preserves_angle() -> None:
    raw = (
        "Cinematic desert dunes. Empty environment — no car, no people. "
        "Landscape 16:9, photorealistic."
    )
    user_text = build_inplace_edit_user_text(sanitize_inplace_background_prompt(raw))

    assert "SOURCE PHOTO" in user_text
    assert "SOURCE VEHICLE IDENTITY" in user_text
    assert "REQUESTED MODIFICATION" in user_text
    assert "16:9" not in user_text
    assert "camera angle" in user_text.lower() or "camera viewpoint" in user_text.lower()


def test_format_vehicle_identity_omits_null_fields() -> None:
    text = format_vehicle_identity(
        {
            "make": "BMW",
            "model": "M4",
            "generation": None,
            "body_color": "Alpine White",
        }
    )

    assert "Make: BMW" in text
    assert "Model: M4" in text
    assert "Body color: Alpine White" in text
    assert "Generation:" not in text


def test_build_background_environment_prompt_exterior() -> None:
    prompt = build_background_environment_prompt("Desert sunset.", angle="three_quarter_left")
    assert prompt.startswith("Desert sunset.")
    assert "ONLY the background" in prompt
