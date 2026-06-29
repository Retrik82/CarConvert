import shutil
from decimal import Decimal
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.user_car import SavedRender, UserCar
from app.repositories.photo_job_repository import PhotoJobRepository
from app.repositories.user_car_repository import UserCarRepository

settings = get_settings()


def _my_cars_root(user_id: str) -> Path:
    path = Path(settings.upload_dir) / "my-cars" / user_id
    path.mkdir(parents=True, exist_ok=True)
    return path


def _render_dir(user_id: str, car_id: str) -> Path:
    path = _my_cars_root(user_id) / car_id
    path.mkdir(parents=True, exist_ok=True)
    return path


def _guess_ext(path: Path, default: str = ".jpg") -> str:
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg", ".png", ".webp"}:
        return suffix
    return default


class UserCarService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._cars = UserCarRepository(db)
        self._jobs = PhotoJobRepository(db)

    async def list_cars(self, user_id: str) -> list[UserCar]:
        return await self._cars.list_for_user(user_id)

    async def create_car(self, user_id: str, name: str) -> UserCar:
        car = UserCar(user_id=user_id, name=name.strip() or "My Car")
        await self._cars.add_car(car)
        reloaded = await self._cars.get_for_user(car.id, user_id)
        return reloaded or car

    async def update_car_name(self, car_id: str, user_id: str, name: str) -> UserCar | None:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return None
        car.name = name.strip() or car.name
        await self._db.flush()
        return car

    async def delete_car(self, car_id: str, user_id: str) -> bool:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return False
        car_dir = _my_cars_root(user_id) / car_id
        await self._cars.delete_car(car)
        if car_dir.is_dir():
            shutil.rmtree(car_dir, ignore_errors=True)
        return True

    async def add_render(
        self,
        car_id: str,
        user_id: str,
        *,
        job_id: str | None = None,
        name: str | None = None,
        original_bytes: bytes | None = None,
        rendered_bytes: bytes | None = None,
        rendered_ext: str = "png",
        quality_score: Decimal | float | None = None,
    ) -> SavedRender | None:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return None

        render = SavedRender(
            car_id=car.id,
            user_id=user_id,
            job_id=job_id,
            name=name.strip() if name else None,
            quality_score=Decimal(str(quality_score)) if quality_score is not None else None,
        )
        await self._cars.add_render(render)

        render_dir = _render_dir(user_id, car.id)
        if job_id and (original_bytes is None or rendered_bytes is None):
            job = await self._jobs.get_for_user(job_id, user_id)
            if job:
                if original_bytes is None and job.original_path:
                    original_file = Path(job.original_path)
                    if original_file.is_file():
                        original_bytes = original_file.read_bytes()
                if rendered_bytes is None and job.result_path and job.status == "completed":
                    rendered_file = Path(job.result_path)
                    if rendered_file.is_file():
                        rendered_bytes = rendered_file.read_bytes()
                        rendered_ext = _guess_ext(rendered_file, ".png").lstrip(".")

        if original_bytes:
            ext = ".jpg"
            original_path = render_dir / f"{render.id}-original{ext}"
            original_path.write_bytes(original_bytes)
            render.original_path = str(original_path)

        if rendered_bytes:
            safe_ext = rendered_ext.lower().lstrip(".")
            if safe_ext not in {"jpg", "jpeg", "png", "webp"}:
                safe_ext = "png"
            rendered_path = render_dir / f"{render.id}-rendered.{safe_ext}"
            rendered_path.write_bytes(rendered_bytes)
            render.rendered_path = str(rendered_path)

        await self._db.flush()
        return render

    async def update_render_name(
        self,
        car_id: str,
        render_id: str,
        user_id: str,
        name: str,
    ) -> SavedRender | None:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return None
        render = next((item for item in car.renders if item.id == render_id), None)
        if render is None:
            return None
        render.name = name.strip() or render.name
        await self._db.flush()
        return render

    async def get_render(self, car_id: str, render_id: str, user_id: str) -> SavedRender | None:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return None
        return next((item for item in car.renders if item.id == render_id), None)

    async def delete_render(self, car_id: str, render_id: str, user_id: str) -> bool:
        car = await self._cars.get_for_user(car_id, user_id)
        if car is None:
            return False
        render = next((item for item in car.renders if item.id == render_id), None)
        if render is None:
            return False

        for path_str in (render.original_path, render.rendered_path):
            if path_str:
                path = Path(path_str)
                if path.is_file():
                    path.unlink(missing_ok=True)

        await self._cars.delete_render(render)
        await self._db.flush()
        self._db.expire(car)

        remaining = await self._cars.get_for_user(car_id, user_id)
        if remaining is not None and not remaining.renders:
            await self.delete_car(car_id, user_id)
        return True

    def get_render_image_path(self, render: SavedRender, kind: str) -> Path | None:
        if kind == "original":
            path_str = render.original_path
        elif kind == "rendered":
            path_str = render.rendered_path
        else:
            return None
        if not path_str:
            return None
        path = Path(path_str)
        return path if path.is_file() else None

    async def repair_render_image(
        self,
        render: SavedRender,
        car_id: str,
        user_id: str,
        kind: str,
    ) -> Path | None:
        """Copy missing render files from the source photo job when possible."""
        existing = self.get_render_image_path(render, kind)
        if existing is not None:
            return existing

        if not render.job_id:
            return None

        job = await self._jobs.get_for_user(render.job_id, user_id)
        if not job:
            return None

        source_bytes: bytes | None = None
        rendered_ext = "png"
        if kind == "original" and job.original_path:
            original_file = Path(job.original_path)
            if original_file.is_file():
                source_bytes = original_file.read_bytes()
        elif kind == "rendered" and job.result_path and job.status == "completed":
            rendered_file = Path(job.result_path)
            if rendered_file.is_file():
                source_bytes = rendered_file.read_bytes()
                rendered_ext = _guess_ext(rendered_file, ".png").lstrip(".")

        if not source_bytes:
            return None

        render_dir = _render_dir(user_id, car_id)
        if kind == "original":
            original_path = render_dir / f"{render.id}-original.jpg"
            original_path.write_bytes(source_bytes)
            render.original_path = str(original_path)
        else:
            safe_ext = rendered_ext.lower().lstrip(".")
            if safe_ext not in {"jpg", "jpeg", "png", "webp"}:
                safe_ext = "png"
            rendered_path = render_dir / f"{render.id}-rendered.{safe_ext}"
            rendered_path.write_bytes(source_bytes)
            render.rendered_path = str(rendered_path)

        await self._db.flush()
        return self.get_render_image_path(render, kind)
