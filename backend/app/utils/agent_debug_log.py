import json
import time
from pathlib import Path

_LOG_PATH = Path(__file__).resolve().parents[3] / "debug-a2972d.log"
_SESSION_ID = "a2972d"


def agent_log(
    *,
    location: str,
    message: str,
    data: dict | None = None,
    hypothesis_id: str = "",
    run_id: str = "post-fix",
) -> None:
    # #region agent log
    try:
        payload = {
            "sessionId": _SESSION_ID,
            "id": f"log_{int(time.time() * 1000)}",
            "timestamp": int(time.time() * 1000),
            "location": location,
            "message": message,
            "data": data or {},
            "runId": run_id,
            "hypothesisId": hypothesis_id,
        }
        with _LOG_PATH.open("a", encoding="utf-8") as f:
            f.write(json.dumps(payload, ensure_ascii=False) + "\n")
    except Exception:
        pass
    # #endregion
