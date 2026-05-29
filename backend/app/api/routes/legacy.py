import os

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.models.schemas import EditResponse
from app.services.ai.desert_processor import edit_car_background_custom
from app.utils.image_utils import normalize_content_type, to_data_url, validate_image_upload

router = APIRouter(tags=["legacy"])
settings = get_settings()


@router.post("/api/edit", response_model=EditResponse)
async def edit_image(image: UploadFile = File(...), prompt: str = Form(...)) -> JSONResponse:
    api_key = os.getenv("OPENROUTER_API_KEY", settings.openrouter_api_key).strip()
    if not api_key or api_key == "your_key_here":
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not configured.")

    user_prompt = prompt.strip()
    if len(user_prompt) < 3:
        raise HTTPException(status_code=422, detail="Prompt must be at least 3 characters.")

    try:
        image_bytes = await image.read()
        filename = image.filename or "photo.jpg"
        content_type = normalize_content_type(filename, image.content_type)
        validate_image_upload(filename, content_type, image_bytes)
        source_data_url = to_data_url(image_bytes, content_type)
        generated_base64, mime_type = await edit_car_background_custom(user_prompt, source_data_url, api_key)
    except ValueError as exc:
        message = str(exc)
        if "10MB" in message:
            raise HTTPException(status_code=413, detail=message) from exc
        if "Unsupported" in message:
            raise HTTPException(status_code=415, detail=message) from exc
        raise HTTPException(status_code=400, detail=message) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Unexpected server error.") from exc

    return JSONResponse(
        status_code=200,
        content={
            "success": True,
            "image_base64": generated_base64,
            "mime_type": mime_type,
            "message": "Image generated successfully.",
            "error": None,
        },
    )
