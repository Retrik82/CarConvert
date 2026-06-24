import asyncio
import base64
import json
import logging
from typing import Any

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_from_token
from app.config import get_settings
from app.db.session import AsyncSessionLocal
from app.models.schemas import HintResponse
from app.services.ai.hint_analyzer import analyze_frame
from app.services.ai.concurrency import hint_slot
from app.services.session_service import SessionService
from app.utils.image_utils import resize_for_preview, to_data_url

logger = logging.getLogger(__name__)
settings = get_settings()
router = APIRouter()

_session_locks: dict[str, asyncio.Lock] = {}


def _get_lock(session_id: str) -> asyncio.Lock:
    if session_id not in _session_locks:
        _session_locks[session_id] = asyncio.Lock()
    return _session_locks[session_id]


@router.websocket("/camera/stream")
async def camera_stream(
    websocket: WebSocket,
    session_id: str = Query(...),
    token: str = Query(...),
) -> None:
    await websocket.accept()

    async with AsyncSessionLocal() as db:
        user = await get_current_user_from_token(token, db)
        if not user:
            await websocket.send_json({"type": "error", "message": "Unauthorized"})
            await websocket.close(code=4401)
            return

        session = await SessionService(db).get_active_session(session_id, user.id)
        if not session:
            await websocket.send_json({"type": "error", "message": "Invalid session"})
            await websocket.close(code=4403)
            return

    lock = _get_lock(session_id)
    await websocket.send_json({"type": "connected", "session_id": session_id})

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                payload: dict[str, Any] = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_json({"type": "error", "message": "Invalid JSON"})
                continue

            if payload.get("type") != "frame":
                continue

            image_b64 = payload.get("image_base64", "")
            mime_type = payload.get("mime_type", "image/jpeg")
            if not image_b64:
                continue

            if lock.locked():
                continue

            async with lock:
                try:
                    image_bytes = base64.b64decode(image_b64)
                    if len(image_bytes) > settings.max_preview_bytes:
                        preview_bytes, mime_type = resize_for_preview(image_bytes)
                    else:
                        preview_bytes, mime_type = resize_for_preview(image_bytes)

                    data_url = to_data_url(preview_bytes, mime_type)
                    async with hint_slot():
                        hint: HintResponse = await analyze_frame(data_url, settings.openrouter_api_key)
                    await websocket.send_json(hint.model_dump())
                except Exception as exc:
                    logger.warning("Frame analysis error: %s", exc)
                    await websocket.send_json(
                        HintResponse(
                            hint="align_car",
                            message="Продолжай наводить камеру",
                            confidence=0.3,
                        ).model_dump()
                    )
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected session=%s", session_id)
    finally:
        _session_locks.pop(session_id, None)
