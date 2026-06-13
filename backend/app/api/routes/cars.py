from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from app.models.schemas import CarCatalogResponse, CarModelOut
from app.services.car_asset_service import (
    CAR_MODEL,
    CAR_PAINTS,
    CAR_VIEWS,
    get_image_path,
    image_url,
)

router = APIRouter(prefix="/cars", tags=["cars"])


@router.get("", response_model=CarCatalogResponse)
async def list_car_models() -> CarCatalogResponse:
    return CarCatalogResponse(
        models=[
            CarModelOut(
                id=CAR_MODEL,
                name="BMW M4 Coupe (G82)",
                views=list(CAR_VIEWS),
                paints=list(CAR_PAINTS),
                default_view="side_right",
                preview_url=image_url(CAR_MODEL, "side_right", "white"),
            )
        ]
    )


@router.get("/image/{model}/{view}/{paint}")
async def get_car_image(model: str, view: str, paint: str):
    image_path = get_image_path(model, view, paint)
    if image_path is None:
        raise HTTPException(status_code=404, detail="Car image not found.")
    return FileResponse(image_path, media_type="image/png")
