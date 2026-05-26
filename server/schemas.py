from pydantic import BaseModel


class EditResponse(BaseModel):
    success: bool
    image_base64: str | None = None
    mime_type: str | None = None
    message: str | None = None
    error: str | None = None
