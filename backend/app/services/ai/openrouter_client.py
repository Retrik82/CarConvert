import asyncio
import json
import logging
import re
from typing import Any

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


def _extract_image_reference(payload: dict[str, Any]) -> str:
    def looks_like_base64(value: str) -> bool:
        if len(value) < 128:
            return False
        return bool(re.fullmatch(r"[A-Za-z0-9+/=\r\n]+", value))

    def scan_node(node: Any) -> str | None:
        if isinstance(node, str):
            text = node.strip()
            if text.startswith("data:image") or text.startswith("http://") or text.startswith("https://"):
                return text
            md_match = re.search(r"https?://[^\s)]+", text)
            if md_match:
                return md_match.group(0)
            if looks_like_base64(text):
                return f"data:image/png;base64,{text.replace(chr(10), '').replace(chr(13), '')}"
            return None
        if isinstance(node, list):
            for item in node:
                found = scan_node(item)
                if found:
                    return found
            return None
        if isinstance(node, dict):
            for key in ("image_url", "url", "b64_json", "base64", "image_base64", "data", "content", "output", "images"):
                if key not in node:
                    continue
                value = node[key]
                if key in {"b64_json", "base64", "image_base64"} and isinstance(value, str):
                    return f"data:image/png;base64,{value}"
                found = scan_node(value)
                if found:
                    return found
            for value in node.values():
                found = scan_node(value)
                if found:
                    return found
        return None

    choices = payload.get("choices", [])
    if not choices:
        raise ValueError("OpenRouter returned no choices.")

    message = choices[0].get("message", {})
    content = message.get("content")

    images = message.get("images")
    if isinstance(images, list) and images:
        first = images[0]
        if isinstance(first, str):
            if first.startswith("data:image"):
                return first
            return f"data:image/png;base64,{first}"
        if isinstance(first, dict):
            image_url = first.get("image_url")
            if isinstance(image_url, dict) and image_url.get("url"):
                return image_url["url"]
            if isinstance(image_url, str):
                return image_url
            if isinstance(first.get("url"), str):
                return first["url"]
            if isinstance(first.get("b64_json"), str):
                return f"data:image/png;base64,{first['b64_json']}"

    if isinstance(content, list):
        for part in content:
            if not isinstance(part, dict):
                continue
            image_url = part.get("image_url")
            if isinstance(image_url, dict) and image_url.get("url"):
                return image_url["url"]
            if isinstance(image_url, str):
                return image_url
            if isinstance(part.get("url"), str):
                return part["url"]
            if isinstance(part.get("b64_json"), str):
                return f"data:image/png;base64,{part['b64_json']}"

    found = scan_node(content) or scan_node(payload.get("images")) or scan_node(payload)
    if found:
        return found

    raise ValueError(f"Could not extract image from OpenRouter response. Keys: {sorted(payload.keys())}")


class OpenRouterClient:
    def __init__(self, api_key: str | None = None) -> None:
        self.api_key = api_key or settings.openrouter_api_key

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    async def chat_completion(
        self,
        model: str,
        messages: list[dict[str, Any]],
        timeout: float,
        max_tokens: int = 512,
        response_format: dict[str, str] | None = None,
        modalities: list[str] | None = None,
        image_config: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
        }
        if response_format:
            payload["response_format"] = response_format
        if modalities:
            payload["modalities"] = modalities
        if image_config:
            payload["image_config"] = image_config
        last_error: Exception | None = None
        for attempt in range(3):
            try:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.post(
                        OPENROUTER_URL,
                        headers=self._headers(),
                        json=payload,
                    )
                if response.status_code in {429, 500, 502, 503, 504} and attempt < 2:
                    await asyncio.sleep(0.5 * (2**attempt))
                    continue
                if response.status_code >= 400:
                    raise RuntimeError(
                        f"OpenRouter request failed ({response.status_code}): {response.text}"
                    )
                return response.json()
            except (httpx.TimeoutException, httpx.RequestError) as exc:
                last_error = exc
                if attempt < 2:
                    await asyncio.sleep(0.5 * (2**attempt))
                    continue
                raise RuntimeError(f"OpenRouter network error: {exc}") from exc
        raise RuntimeError(str(last_error or "OpenRouter request failed"))

    async def generate_image_completion(
        self,
        model: str,
        messages: list[dict[str, Any]],
        timeout: float,
        *,
        aspect_ratio: str = "16:9",
        image_size: str = "1K",
        max_tokens: int = 1024,
    ) -> dict[str, Any]:
        """Text-to-image or image-edit completion via OpenRouter multimodal models."""
        return await self.chat_completion(
            model,
            messages,
            timeout,
            max_tokens=max_tokens,
            modalities=["image", "text"],
            image_config={"aspect_ratio": aspect_ratio, "image_size": image_size},
        )

    async def chat_text(
        self,
        model: str,
        messages: list[dict[str, Any]],
        timeout: float,
        max_tokens: int = 512,
        response_format: dict[str, str] | None = None,
    ) -> str:
        body = await self.chat_completion(
            model, messages, timeout, max_tokens, response_format=response_format
        )
        choices = body.get("choices", [])
        if not choices:
            raise ValueError("OpenRouter returned no choices.")
        content = choices[0].get("message", {}).get("content", "")
        if isinstance(content, list):
            parts = []
            for part in content:
                if isinstance(part, dict) and part.get("type") == "text":
                    parts.append(part.get("text", ""))
            return "".join(parts)
        return str(content)

    async def generate_image(
        self,
        model: str,
        system_prompt: str,
        user_text: str,
        source_data_url: str,
        timeout: float,
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
        body = await self.generate_image_completion(
            model, messages, timeout, max_tokens=max_tokens
        )
        image_ref = _extract_image_reference(body)
        if image_ref.startswith("data:image"):
            header = image_ref.split(",", 1)[0]
            mime_type = header.replace("data:", "").replace(";base64", "")
            base64_data = image_ref.split(",", 1)[1]
            return base64_data, mime_type

        async with httpx.AsyncClient(timeout=timeout) as client:
            image_response = await client.get(image_ref)
        if image_response.status_code >= 400:
            raise RuntimeError(f"Failed to download generated image ({image_response.status_code}).")
        mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
        import base64

        encoded = base64.b64encode(image_response.content).decode("utf-8")
        return encoded, mime_type

    @staticmethod
    def parse_json_from_text(text: str) -> dict[str, Any]:
        text = text.strip()
        if text.startswith("```"):
            text = re.sub(r"^```(?:json)?\s*", "", text)
            text = re.sub(r"\s*```$", "", text)
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            raise
