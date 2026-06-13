from app.config import get_settings
from app.services.ai.openrouter_client import OpenRouterClient

settings = get_settings()

BACKGROUND_SYSTEM_PROMPT = (
    "Keep the exact same vehicle. "
    "Do not modify body shape, wheels, headlights, paint, reflections, or proportions. "
    "Only replace the background. "
    "Preserve the exact car. "
    "Photorealistic result."
)


async def process_with_background(
    source_data_url: str,
    background_prompt: str,
    reference_data_url: str | None = None,
    api_key: str | None = None,
) -> tuple[str, str]:
    client = OpenRouterClient(api_key)
    user_text = (
        f"Replace the background with the following scene ONLY. "
        f"Match lighting, perspective, and natural shadows. "
        f"No text, watermarks, or artifacts. "
        f"Background description: {background_prompt}"
    )
    if reference_data_url:
        user_text += " Use the reference background image for scene style and perspective."

    content: list[dict] = [{"type": "text", "text": user_text}]
    if reference_data_url:
        content.append({"type": "image_url", "image_url": {"url": reference_data_url}})
    content.append({"type": "image_url", "image_url": {"url": source_data_url}})

    messages = [
        {"role": "system", "content": BACKGROUND_SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]
    body = await client.chat_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
        max_tokens=1024,
    )
    from app.services.ai.openrouter_client import _extract_image_reference
    import base64
    import httpx

    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    async with httpx.AsyncClient(timeout=float(settings.process_timeout_sec)) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download generated image ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type


async def generate_empty_background(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    client = OpenRouterClient(api_key)
    messages = [
        {
            "role": "system",
            "content": (
                "Generate a photorealistic empty environment background image. "
                "No vehicles, no people, no text, no watermarks."
            ),
        },
        {"role": "user", "content": prompt},
    ]
    body = await client.chat_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
        max_tokens=1024,
    )
    from app.services.ai.openrouter_client import _extract_image_reference
    import base64
    import httpx

    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    async with httpx.AsyncClient(timeout=float(settings.process_timeout_sec)) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download generated background ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type
