"""Tests for My Cars API."""

from __future__ import annotations

import io
import os
import tempfile
import uuid
from pathlib import Path

_test_db = Path(tempfile.gettempdir()) / f"test_my_cars_{uuid.uuid4().hex}.db"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_test_db.as_posix()}"
os.environ.setdefault("JWT_SECRET", "test_secret_minimum_32_characters_long")
os.environ.setdefault("OPENROUTER_API_KEY", "test_key")

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def _register() -> dict:
    response = client.post(
        "/auth/register",
        json={
            "email": f"user_{uuid.uuid4().hex[:8]}@example.com",
            "password": "TestPass123!",
            "display_name": "Test",
            "device_id": "device-a",
            "device_name": "Pixel Test",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def _auth_headers(data: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {data['access_token']}"}


def test_my_cars_crud() -> None:
    auth = _auth_headers(_register())

    create = client.post("/my-cars", json={"name": "BMW M4"}, headers=auth)
    assert create.status_code == 200, create.text
    car = create.json()
    car_id = car["id"]
    assert car["name"] == "BMW M4"

    listed = client.get("/my-cars", headers=auth)
    assert listed.status_code == 200
    assert len(listed.json()["cars"]) == 1

    original = b"\xff\xd8\xff" + b"original-bytes"
    rendered = b"\x89PNG\r\n\x1a\n" + b"rendered-bytes"
    saved = client.post(
        f"/my-cars/{car_id}/renders",
        data={"job_id": "job-123", "name": "Desert render", "rendered_ext": "png"},
        files={
            "original": ("original.jpg", io.BytesIO(original), "image/jpeg"),
            "rendered": ("rendered.png", io.BytesIO(rendered), "image/png"),
        },
        headers=auth,
    )
    assert saved.status_code == 200, saved.text
    render = saved.json()
    assert render["name"] == "Desert render"
    assert render["has_original"] is True
    assert render["has_rendered"] is True

    image = client.get(
        f"/my-cars/{car_id}/renders/{render['id']}/image/rendered",
        headers=auth,
    )
    assert image.status_code == 200
    assert image.content.startswith(b"\x89PNG")

    renamed = client.patch(f"/my-cars/{car_id}", json={"name": "Track BMW"}, headers=auth)
    assert renamed.status_code == 200
    assert renamed.json()["name"] == "Track BMW"

    deleted = client.delete(f"/my-cars/{car_id}/renders/{render['id']}", headers=auth)
    assert deleted.status_code == 200

    after_delete = client.get("/my-cars", headers=auth)
    assert after_delete.status_code == 200
    assert after_delete.json()["cars"] == []
