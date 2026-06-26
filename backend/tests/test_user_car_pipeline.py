from app.db.models.background import ANGLE_PROMPT_SUFFIXES
from app.services.user_car_pipeline import ResolvedBackground, build_background_replace_prompt


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


def test_background_replace_prompt_interior() -> None:
    resolved = ResolvedBackground(
        prompt="Warm leather interior studio.",
        angle="interior",
    )
    prompt = build_background_replace_prompt(resolved)

    assert "cabin interior" in prompt
    assert "Camera:" not in prompt
