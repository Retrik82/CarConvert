"""Quick prod API smoke test (register, history, photo with octet-stream)."""
import io
import json
import time
import uuid
from pathlib import Path

import urllib.error
import urllib.request
from PIL import Image

BASE = "https://carconvert-api.onrender.com"
LOG = Path(__file__).resolve().parents[2] / "debug-a2972d.log"


def request(method: str, path: str, data=None, headers=None, raw_body=None, timeout=90):
    h = dict(headers or {})
    body = raw_body
    if data is not None:
        body = json.dumps(data).encode()
        h.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(BASE + path, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode()


def main() -> None:
    email = f"debug_{uuid.uuid4().hex[:8]}@example.com"
    password = "TestPass123!"
    results: dict = {"email": email}

    code, body = request(
        "POST",
        "/auth/register",
        {"email": email, "password": password, "display_name": "Debug"},
    )
    results["register"] = {"code": code, "body": body[:300]}
    if code != 200:
        _write_log(results)
        print(json.dumps(results, indent=2))
        return

    access = json.loads(body)["access_token"]
    auth = {"Authorization": f"Bearer {access}"}

    code, body = request("GET", "/photos/history", headers=auth)
    results["history"] = {"code": code, "body": body[:300]}

    buf = io.BytesIO()
    Image.new("RGB", (64, 64), "red").save(buf, format="JPEG")
    jpeg = buf.getvalue()
    boundary = "----BoundaryE2E"
    multipart = (
        f"--{boundary}\r\n"
        'Content-Disposition: form-data; name="image"; filename="capture.jpg"\r\n'
        "Content-Type: application/octet-stream\r\n\r\n"
    ).encode("latin-1") + jpeg + f"\r\n--{boundary}--\r\n".encode("latin-1")

    code, body = request(
        "POST",
        "/photo/process",
        headers={
            **auth,
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
        raw_body=multipart,
        timeout=120,
    )
    results["process_octet_stream"] = {"code": code, "body": body[:400]}

    _write_log(results)
    print(json.dumps(results, indent=2))


def _write_log(data: dict) -> None:
    entry = {
        "sessionId": "a2972d",
        "runId": "prod-e2e",
        "location": "prod_e2e_check.py",
        "message": "prod_api_check",
        "data": data,
        "timestamp": int(time.time() * 1000),
    }
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
