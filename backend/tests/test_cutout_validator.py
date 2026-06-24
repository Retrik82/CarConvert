"""Tests for cutout validation."""

from app.services.ai.cutout_validator import validate_cutout


def test_rejects_empty_bytes():
    ok, reason = validate_cutout(b"")
    assert not ok
    assert "empty" in reason.lower()


def test_rejects_tiny_invalid_image():
    ok, reason = validate_cutout(b"not-an-image")
    assert not ok
