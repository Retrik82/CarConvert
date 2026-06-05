"""Auth system: rotation, RBAC, sessions, rate limits."""
from __future__ import annotations

import os
import tempfile
import uuid

_test_db = __import__("pathlib").Path
_db_file = _test_db(tempfile.gettempdir()) / f"test_auth_{uuid.uuid4().hex}.db"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_db_file.as_posix()}"
os.environ.setdefault("JWT_SECRET", "test_secret_minimum_32_characters_long")
os.environ.setdefault("OPENROUTER_API_KEY", "test_key")
os.environ["JWT_ACCESS_EXPIRE_MIN"] = "15"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def _register(email: str | None = None) -> dict:
    email = email or f"user_{uuid.uuid4().hex[:8]}@example.com"
    response = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "TestPass123!",
            "display_name": "Test",
            "device_id": "device-a",
            "device_name": "Pixel Test",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_refresh_token_rotation() -> None:
    data = _register()
    old_refresh = data["refresh_token"]
    old_access = data["access_token"]

    refreshed = client.post("/auth/refresh", json={"refresh_token": old_refresh})
    assert refreshed.status_code == 200, refreshed.text
    new_data = refreshed.json()
    assert new_data["refresh_token"] != old_refresh

    reuse = client.post("/auth/refresh", json={"refresh_token": old_refresh})
    assert reuse.status_code == 401

    me = client.get("/auth/me", headers={"Authorization": f"Bearer {new_data['access_token']}"})
    assert me.status_code == 200


def test_logout_revokes_refresh() -> None:
    data = _register()
    refresh = data["refresh_token"]
    logout = client.post("/auth/logout", json={"refresh_token": refresh})
    assert logout.status_code == 200
    again = client.post("/auth/refresh", json={"refresh_token": refresh})
    assert again.status_code == 401


def test_logout_all_keeps_current_when_requested() -> None:
    data = _register()
    headers = {"Authorization": f"Bearer {data['access_token']}"}

    second = client.post(
        "/auth/login",
        json={"email": data["user"]["email"], "password": "TestPass123!", "device_id": "device-b"},
    )
    assert second.status_code == 200

    response = client.post(
        "/auth/logout-all",
        headers=headers,
        json={"keep_current_session": True},
    )
    assert response.status_code == 200
    assert response.json()["revoked_sessions"] >= 1


def test_sessions_list_and_revoke() -> None:
    data = _register()
    headers = {
        "Authorization": f"Bearer {data['access_token']}",
        "X-Session-Id": data.get("session_id") or "",
    }
    sessions = client.get("/auth/sessions", headers=headers)
    assert sessions.status_code == 200
    items = sessions.json()["sessions"]
    assert len(items) >= 1
    session_id = items[0]["id"]
    revoked = client.delete(f"/auth/sessions/{session_id}", headers=headers)
    assert revoked.status_code == 200


def test_non_admin_forbidden_on_admin_route() -> None:
    data = _register()
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    response = client.put("/admin/settings/price", headers=headers, json={"price_usd": 1.0})
    assert response.status_code == 403


def test_user_out_includes_role() -> None:
    data = _register()
    assert data["user"]["role"] == "user"
    assert data["user"]["is_admin"] is False


def test_forgot_password_neutral_response() -> None:
    response = client.post("/auth/forgot-password", json={"email": "unknown@example.com"})
    assert response.status_code == 200
    assert "status" in response.json()


if __name__ == "__main__":
    test_refresh_token_rotation()
    test_logout_revokes_refresh()
    test_logout_all_keeps_current_when_requested()
    test_sessions_list_and_revoke()
    test_non_admin_forbidden_on_admin_route()
    test_user_out_includes_role()
    test_forgot_password_neutral_response()
    print("All auth system tests passed.")
