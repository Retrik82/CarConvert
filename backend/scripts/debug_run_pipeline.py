#!/usr/bin/env python3
"""Debug: run photo pipeline end-to-end with a local image (no queue/auth)."""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.config import get_settings
from app.services.ai.pose_classifier import classify_car_pose_angle
from app.services.background_service import BackgroundService
from app.services.user_car_pipeline import process_user_car_photo, ResolvedBackground
from app.utils.debug_log import agent_log
from app.utils.image_utils import to_data_url


async def main(image_path: Path) -> int:
    settings = get_settings()
    api_key = settings.openrouter_api_key

    agent_log(
        hypothesis_id="E",
        location="debug_run_pipeline.py:main",
        message="script_start",
        data={
            "image": str(image_path),
            "image_exists": image_path.is_file(),
            "api_key_set": bool(api_key and api_key != "your_key_here"),
            "api_key_len": len(api_key or ""),
        },
        run_id="script",
    )

    if not api_key or api_key == "your_key_here":
        print("OPENROUTER_API_KEY not set in backend/.env")
        return 1

    if not image_path.is_file():
        print(f"Image not found: {image_path}")
        return 1

    image_bytes = image_path.read_bytes()
    data_url = to_data_url(image_bytes, "image/jpeg")
    print(f"Image size: {len(image_bytes)} bytes")

    print("Step 1: pose classification (OpenRouter)...")
    angle = await classify_car_pose_angle(data_url, api_key)
    print(f"  angle={angle}")

    # Minimal resolved background (preset scene bundled)
    from app.services.background_asset_service import ensure_preset_scene

    scene_path = ensure_preset_scene("gray-showroom", angle)
    resolved = ResolvedBackground(
        prompt="Minimalist luxury gray automotive showroom studio.",
        angle=angle,
        preset_slug="gray-showroom",
        scene_image_path=str(scene_path),
    )

    print("Step 2: cutout + composite (OpenRouter)...")
    result_b64, mime = await process_user_car_photo(data_url, resolved, api_key)
    out = ROOT / "data" / "debug_pipeline_result.jpg"
    out.parent.mkdir(parents=True, exist_ok=True)
    import base64

    out.write_bytes(base64.b64decode(result_b64))
    agent_log(
        hypothesis_id="D",
        location="debug_run_pipeline.py:main",
        message="pipeline_success",
        data={"output": str(out), "mime": mime, "result_bytes": len(result_b64)},
        run_id="script",
    )
    print(f"OK -> {out} ({mime})")
    return 0


if __name__ == "__main__":
    default_img = (
        ROOT.parent
        / "assets"
        / "c__Users_Artsiom_AppData_Roaming_Cursor_User_workspaceStorage_aff6c8f4ac58e700e99ef7f702b86537_images_image-04705884-ab27-4a6a-8032-1882f3723feb.png"
    )
    img = Path(sys.argv[1]) if len(sys.argv) > 1 else default_img
    raise SystemExit(asyncio.run(main(img)))
