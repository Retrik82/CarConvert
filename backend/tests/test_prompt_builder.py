"""Tests for prompt assembly and validation."""

from app.services.ai.prompt_blocks import (
    BACKGROUND_REPLACE_SYSTEM_PROMPT,
    CAR_EXTRACT_SYSTEM_PROMPT,
    REQUIRED_SYSTEM_MARKERS,
)
from app.services.ai.prompt_builder import (
    build_extract_user_text,
    build_inplace_edit_user_text,
    ensure_prompt_compliance,
)


def test_system_prompts_contain_required_markers() -> None:
    for marker in REQUIRED_SYSTEM_MARKERS:
        assert marker in BACKGROUND_REPLACE_SYSTEM_PROMPT
    for marker in ("source of truth", "Forbidden", "Preserve every original design feature"):
        assert marker in CAR_EXTRACT_SYSTEM_PROMPT


def test_inplace_user_prompt_includes_identity_and_modification_scope() -> None:
    user_text = build_inplace_edit_user_text(
        "Gray showroom studio.",
        vehicle_descriptor={"make": "Audi", "model": "RS6", "body_color": "Nardo Gray"},
    )

    assert "SOURCE VEHICLE IDENTITY" in user_text
    assert "Make: Audi" in user_text
    assert "REQUESTED MODIFICATION" in user_text
    assert "Replace ONLY the background" in user_text
    assert "Preserve every original design feature" in user_text
    assert "studio scene" in user_text.lower()
    assert "small detail" in user_text.lower()


def test_extract_user_prompt_preserves_vehicle_details() -> None:
    user_text = build_extract_user_text(
        vehicle_descriptor={"wheels": "20-inch black alloys", "headlight_shape": "LED DRL strips"},
    )

    assert "Wheels: 20-inch black alloys" in user_text
    assert "REQUESTED MODIFICATION" in user_text
    assert "Remove background only" in user_text


def test_ensure_prompt_compliance_repairs_missing_markers() -> None:
    system, user = ensure_prompt_compliance("Minimal system prompt.", "Minimal user prompt.")

    assert "Preserve every original design feature" in system
    assert "SOURCE VEHICLE IDENTITY" in user or "Preserve every original design feature" in user
