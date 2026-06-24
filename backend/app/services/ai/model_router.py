"""Route OpenRouter calls through primary → retry → fallback chains."""

from __future__ import annotations

import asyncio
import logging
from typing import Any, Callable, TypeVar

import httpx

from app.config import get_settings
from app.services.ai.openrouter_client import OpenRouterClient, _extract_image_reference

logger = logging.getLogger(__name__)
settings = get_settings()

T = TypeVar("T")


def _is_retryable(exc: Exception) -> bool:
    if isinstance(exc, httpx.TimeoutException | httpx.RequestError):
        return True
    if isinstance(exc, RuntimeError):
        text = str(exc).lower()
        return any(code in text for code in ("429", "500", "502", "503", "504", "timeout", "network"))
    return False


async def _with_retries(
    operation: Callable[[], Any],
    *,
    label: str,
    max_retries: int | None = None,
) -> T:
    retries = settings.openrouter_max_retries if max_retries is None else max_retries
    last_error: Exception | None = None
    for attempt in range(retries + 1):
        try:
            return await operation()
        except Exception as exc:
            last_error = exc
            if attempt < retries and _is_retryable(exc):
                delay = 0.5 * (2**attempt)
                logger.info("%s retry %s/%s after %s", label, attempt + 1, retries, exc)
                await asyncio.sleep(delay)
                continue
            raise
    raise RuntimeError(str(last_error or f"{label} failed"))


async def call_vision_text(
    messages: list[dict[str, Any]],
    *,
    primary: str,
    fallback: str | None,
    timeout: float,
    max_tokens: int = 512,
    use_json_mode: bool = True,
    api_key: str | None = None,
) -> str:
    client = OpenRouterClient(api_key)
    models = [primary] + ([fallback] if fallback and fallback != primary else [])

    last_error: Exception | None = None
    for model in models:
        for json_mode in ((True, False) if use_json_mode else (False,)):
            try:

                async def _call() -> str:
                    kwargs: dict[str, Any] = {
                        "model": model,
                        "messages": messages,
                        "timeout": timeout,
                        "max_tokens": max_tokens,
                    }
                    if json_mode:
                        kwargs["response_format"] = {"type": "json_object"}
                    return await client.chat_text(**kwargs)

                return await _with_retries(_call, label=f"vision:{model}")
            except Exception as exc:
                last_error = exc
                if json_mode:
                    continue
                logger.warning("Vision model %s failed: %s", model, exc)
    raise RuntimeError(str(last_error or "Vision call failed"))


async def call_vision_json(
    messages: list[dict[str, Any]],
    *,
    primary: str,
    fallback: str | None,
    timeout: float,
    max_tokens: int = 512,
    api_key: str | None = None,
) -> dict[str, Any]:
    client = OpenRouterClient(api_key)
    text = await call_vision_text(
        messages,
        primary=primary,
        fallback=fallback,
        timeout=timeout,
        max_tokens=max_tokens,
        use_json_mode=True,
        api_key=api_key,
    )
    return client.parse_json_from_text(text)


async def call_image_completion(
    messages: list[dict[str, Any]],
    *,
    primary: str,
    fallback: str | None,
    timeout: float,
    max_tokens: int = 1024,
    api_key: str | None = None,
) -> dict[str, Any]:
    client = OpenRouterClient(api_key)
    models = [primary] + ([fallback] if fallback and fallback != primary else [])
    last_error: Exception | None = None

    for model in models:
        try:

            async def _call() -> dict[str, Any]:
                return await client.generate_image_completion(
                    model,
                    messages,
                    timeout,
                    max_tokens=max_tokens,
                )

            return await _with_retries(_call, label=f"image:{model}")
        except Exception as exc:
            last_error = exc
            logger.warning("Image model %s failed: %s", model, exc)
    raise RuntimeError(str(last_error or "Image completion failed"))


async def call_generate_image(
    *,
    system_prompt: str,
    user_text: str,
    source_data_url: str,
    primary: str,
    fallback: str | None,
    timeout: float,
    api_key: str | None = None,
) -> tuple[str, str]:
    messages = [
        {"role": "system", "content": system_prompt},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": user_text},
                {"type": "image_url", "image_url": {"url": source_data_url}},
            ],
        },
    ]
    body = await call_image_completion(
        messages,
        primary=primary,
        fallback=fallback,
        timeout=timeout,
        api_key=api_key,
    )
    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    async with httpx.AsyncClient(timeout=timeout) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download generated image ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    import base64

    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type
