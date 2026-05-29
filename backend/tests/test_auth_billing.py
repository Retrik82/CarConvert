"""Integration tests for auth, admin panel, balance and pricing."""
from __future__ import annotations

import io
import os
import tempfile
import uuid

# Use isolated DB before app import
_test_db = Path = __import__("pathlib").Path
_db_file = _test_db(tempfile.gettempdir()) / f"test_carconvert_{uuid.uuid4().hex}.db"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_db_file.as_posix()}"
os.environ.setdefault("JWT_SECRET", "test_secret_minimum_32_characters_long")
os.environ.setdefault("OPENROUTER_API_KEY", "test_key_for_integration")

from fastapi.testclient import TestClient  # noqa: E402
from PIL import Image  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def _minimal_jpeg() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (32, 32), "red").save(buf, format="JPEG")
    return buf.getvalue()


def _register(email: str, password: str = "TestPass123!", name: str = "Test User") -> dict:
    response = client.post(
        "/auth/register",
        json={"email": email, "password": password, "display_name": name},
    )
    assert response.status_code == 200, response.text
    return response.json()


def _login(login: str, password: str) -> dict:
    response = client.post("/auth/login", json={"email": login, "password": password})
    assert response.status_code == 200, response.text
    return response.json()


def test_admin_login_and_set_price() -> None:
    data = _login("admin", "admin82")
    assert data["user"]["is_admin"] is True
    assert float(data["user"]["balance"]) == 0.0

    headers = {"Authorization": f"Bearer {data['access_token']}"}
    price_resp = client.get("/admin/settings/price", headers=headers)
    assert price_resp.status_code == 200
    assert float(price_resp.json()["price_usd"]) == 0.10

    update_resp = client.put(
        "/admin/settings/price",
        headers=headers,
        json={"price_usd": 0.25},
    )
    assert update_resp.status_code == 200
    assert float(update_resp.json()["price_usd"]) == 0.25


def test_user_gets_initial_balance_and_sees_price() -> None:
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    data = _register(email)
    assert float(data["user"]["balance"]) == 10.0
    assert data["user"]["is_admin"] is False

    headers = {"Authorization": f"Bearer {data['access_token']}"}
    price_resp = client.get("/settings/generation-price", headers=headers)
    assert price_resp.status_code == 200
    assert float(price_resp.json()["price_usd"]) == 0.25


def test_non_admin_cannot_change_price() -> None:
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    data = _register(email)
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    response = client.put("/admin/settings/price", headers=headers, json={"price_usd": 1.0})
    assert response.status_code == 403


def test_reserved_admin_email_blocked() -> None:
    response = client.post(
        "/auth/register",
        json={"email": "admin@admin.com", "password": "TestPass123!", "display_name": "Hacker"},
    )
    assert response.status_code == 409


def test_balance_deducted_on_process_without_openrouter() -> None:
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    data = _register(email)
    headers = {"Authorization": f"Bearer {data['access_token']}"}

    # Reset price to 0.10 for predictable math
    admin = _login("admin", "admin82")
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}
    client.put("/admin/settings/price", headers=admin_headers, json={"price_usd": 0.10})

    headers = {"Authorization": f"Bearer {data['access_token']}"}
    files = {"image": ("test.jpg", _minimal_jpeg(), "image/jpeg")}
    response = client.post("/photo/process", headers=headers, files=files)
    assert response.status_code == 200, response.text
    me = client.get("/auth/me", headers=headers)
    assert float(me.json()["balance"]) == 9.90


def test_insufficient_balance_rejected() -> None:
    email = f"poor_{uuid.uuid4().hex[:8]}@example.com"
    data = _register(email)
    headers = {"Authorization": f"Bearer {data['access_token']}"}

    admin = _login("admin", "admin82")
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}
    client.put("/admin/settings/price", headers=admin_headers, json={"price_usd": 50.0})

    files = {"image": ("test.jpg", _minimal_jpeg(), "image/jpeg")}
    response = client.post("/photo/process", headers=headers, files=files)
    assert response.status_code == 402

    me = client.get("/auth/me", headers=headers)
    assert float(me.json()["balance"]) == 10.0


if __name__ == "__main__":
    test_admin_login_and_set_price()
    test_user_gets_initial_balance_and_sees_price()
    test_non_admin_cannot_change_price()
    test_reserved_admin_email_blocked()
    test_balance_deducted_on_process_without_openrouter()
    test_insufficient_balance_rejected()
    print("All tests passed.")
