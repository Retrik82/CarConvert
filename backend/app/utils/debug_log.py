"""NDJSON debug logging for agent debug sessions."""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

_LOG_PATH = Path(__file__).resolve().parents[3] / "debug-17d0c7.log"
_SESSION = "17d0c7"
_INGEST_URL = "http://127.0.0.1:7534/ingest/926ad504-cc28-45dd-bd18-8be17417dd04"


def agent_log(
    *,
    hypothesis_id: str,
    location: str,
    message: str,
    data: dict[str, Any] | None = None,
    run_id: str = "pre-fix",
) -> None:
    # region agent log
    try:
        payload = {
            "sessionId": _SESSION,
            "runId": run_id,
            "hypothesisId": hypothesis_id,
            "location": location,
            "message": message,
            "data": data or {},
            "timestamp": int(time.time() * 1000),
        }
        line = json.dumps(payload, ensure_ascii=False) + "\n"
        with _LOG_PATH.open("a", encoding="utf-8") as fh:
            fh.write(line)
        try:
            import urllib.request

            req = urllib.request.Request(
                _INGEST_URL,
                data=line.encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "X-Debug-Session-Id": _SESSION,
                },
                method="POST",
            )
            urllib.request.urlopen(req, timeout=0.5)
        except Exception:
            pass
    except Exception:
        pass
    # endregion
