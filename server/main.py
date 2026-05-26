import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

try:
    from .schemas import EditResponse
    from .services.image_utils import to_data_url, validate_image_upload
    from .services.openrouter import edit_car_background
except ImportError:
    from schemas import EditResponse
    from services.image_utils import to_data_url, validate_image_upload
    from services.openrouter import edit_car_background

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env", override=True)


def get_cors_origins() -> list[str]:
    raw_origins = os.getenv("CORS_ORIGINS", "").strip()
    if raw_origins:
        return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]

    frontend_url = os.getenv("FRONTEND_URL", "").strip()
    if frontend_url:
        return [frontend_url]

    return ["http://localhost:5173"]

app = FastAPI(title="Car Background Editor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/edit", response_model=EditResponse)
async def edit_image(image: UploadFile = File(...), prompt: str = Form(...)) -> JSONResponse:
    api_key = os.getenv("OPENROUTER_API_KEY", "").strip()
    if not api_key or api_key == "your_key_here":
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not configured.")

    user_prompt = prompt.strip()
    if len(user_prompt) < 3:
        raise HTTPException(status_code=422, detail="Prompt must be at least 3 characters.")

    try:
        image_bytes = await image.read()
        validate_image_upload(image.filename or "", image.content_type or "", image_bytes)
        source_data_url = to_data_url(image_bytes, image.content_type or "image/jpeg")
        generated_base64, mime_type = edit_car_background(api_key, user_prompt, source_data_url)
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


@app.exception_handler(HTTPException)
async def http_exception_handler(_, exc: HTTPException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "image_base64": None,
            "mime_type": None,
            "message": None,
            "error": exc.detail,
        },
    )
