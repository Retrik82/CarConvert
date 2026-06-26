import base64
import re
from typing import Any

import requests

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL_NAME = "google/gemini-3.1-flash-image-preview"
SYSTEM_PROMPT = (
    "You are an automotive photo editor specializing in background replacement.\n\n"
    "Goal:\n"
    "Replace ONLY the background of the photograph. The vehicle must remain identical.\n\n"
    "Rules:\n"
    "- KEEP the exact same vehicle: make, model, color, paint, wheels, headlights, "
    "body shape, proportions, reflections, and every visible detail.\n"
    "- KEEP the exact same camera angle, perspective, focal length, framing, and vehicle "
    "position in the frame.\n"
    "- Replace ONLY background pixels: sky, ground, walls, buildings, scenery.\n"
    "- Do not regenerate, restyle, substitute, swap, rotate, reposition, or resize the vehicle.\n"
    "- Photorealistic seamless result."
)


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
            preferred_keys = (
                "image_url",
                "url",
                "b64_json",
                "base64",
                "image_base64",
                "data",
                "content",
                "output",
                "images",
            )
            for key in preferred_keys:
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

        return None

    choices = payload.get("choices", [])
    if not choices:
        raise ValueError("OpenRouter returned no choices.")

    message = choices[0].get("message", {})
    content = message.get("content")

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

            if isinstance(part.get("data"), str):
                maybe_data = part["data"]
                if maybe_data.startswith("data:image"):
                    return maybe_data

    found_from_content = scan_node(content)
    if found_from_content:
        return found_from_content

    images = payload.get("images")
    if isinstance(images, list) and images:
        first = images[0]
        if isinstance(first, str):
            if first.startswith("data:image"):
                return first
            return f"data:image/png;base64,{first}"
        if isinstance(first, dict):
            if isinstance(first.get("url"), str):
                return first["url"]
            if isinstance(first.get("b64_json"), str):
                return f"data:image/png;base64,{first['b64_json']}"

    found_from_payload = scan_node(payload)
    if found_from_payload:
        return found_from_payload

    top_keys = ", ".join(sorted(payload.keys()))
    raise ValueError(
        "Could not extract generated image from OpenRouter response. "
        f"Top-level keys: {top_keys}"
    )


def edit_car_background(api_key: str, user_prompt: str, source_data_url: str) -> tuple[str, str]:
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"Background instructions: {user_prompt}",
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": source_data_url},
                    },
                ],
            }
        ],
    }

    response = requests.post(OPENROUTER_URL, headers=headers, json=payload, timeout=120)
    if response.status_code >= 400:
        details = response.text
        raise RuntimeError(f"OpenRouter request failed ({response.status_code}): {details}")

    body = response.json()
    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    image_response = requests.get(image_ref, timeout=120)
    if image_response.status_code >= 400:
        raise RuntimeError(
            f"Failed to download generated image ({image_response.status_code})."
        )

    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type
