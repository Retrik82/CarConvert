"""Assemble and validate image-generation prompts with vehicle identity preservation."""

from __future__ import annotations

import logging

from app.services.ai.prompt_blocks import (
    MINIMAL_INTERVENTION_PHRASES,
    PRESERVATION_REMINDER,
    REQUIRED_SYSTEM_MARKERS,
)
from app.services.ai.vehicle_descriptor import format_vehicle_identity
from app.utils.image_utils import INPLACE_BACKDROP_CONSTRAINTS

logger = logging.getLogger(__name__)


def build_modification_scope(*, task: str, requested_change: str | None = None) -> str:
    """Describe what may change for a given task type."""
    if task == "background_replace":
        return (
            "REQUESTED MODIFICATION: Replace ONLY the background environment. "
            "The vehicle itself must not change in any way."
        )
    if task == "composite":
        return (
            "REQUESTED MODIFICATION: Place the source vehicle into the reference scene. "
            "Adjust only placement, scale, and contact shadows — not vehicle design."
        )
    if task == "extract":
        return (
            "REQUESTED MODIFICATION: Remove background only. "
            "The vehicle pixels and silhouette must remain unchanged."
        )
    if requested_change:
        return (
            f"REQUESTED MODIFICATION: {requested_change.strip()}. "
            "Apply this change ONLY to the specified element. "
            "Everything else remains identical to the source vehicle."
        )
    return (
        "REQUESTED MODIFICATION: None beyond preserving the source vehicle exactly. "
        "Do not alter any vehicle detail."
    )


def build_inplace_edit_user_text(
    background_prompt: str,
    *,
    angle: str = "three_quarter_left",
    vehicle_descriptor: dict | None = None,
) -> str:
    """User message for in-place background replacement."""
    identity_block = format_vehicle_identity(vehicle_descriptor, angle=angle)
    modification_block = build_modification_scope(task="background_replace")

    if angle == "interior":
        locality = (
            "Keep the cabin interior, dashboard, seats, steering wheel, and trim exactly as photographed. "
            "Replace only the environment visible outside the windows."
        )
    else:
        locality = (
            "Keep the vehicle, camera viewpoint, perspective, and framing exactly as photographed. "
            "Replace only the distant scenery behind the car — not the car itself, not the ground under the tires."
        )

    return (
        "SOURCE PHOTO (attached below): edit this photograph in place.\n\n"
        f"{identity_block}\n\n"
        f"New background environment: {background_prompt}\n\n"
        f"{modification_block}\n"
        f"{locality} "
        f"{INPLACE_BACKDROP_CONSTRAINTS} "
        "Do not change the vehicle model, generation, body geometry, proportions, color, wheels, "
        "lights, trim, badges, reflections, or shooting angle. "
        "Preserve every small detail visible in the source photo. "
        "Do not generate a new car or a new camera angle.\n"
        f"{PRESERVATION_REMINDER}"
    )


def build_composite_user_text(
    scene_prompt: str,
    *,
    vehicle_descriptor: dict | None = None,
    cutout: bool = False,
) -> str:
    """User message for scene compositing."""
    identity_block = format_vehicle_identity(vehicle_descriptor)
    modification_block = build_modification_scope(task="composite")

    if cutout:
        image_lines = (
            "Image 1 — BACKGROUND SCENE: target environment. Keep it exactly as shown.\n"
            "Image 2 — USER VEHICLE: transparent cutout to place into the scene."
        )
    else:
        image_lines = (
            "Image 1 — REFERENCE SCENE: fixed studio room with a placeholder car. "
            "Keep this room, camera angle, lighting, floor, podium, and shadows exactly as shown.\n"
            "Image 2 — USER VEHICLE: the car to place into the reference scene."
        )

    return (
        f"{image_lines}\n\n"
        f"{identity_block}\n\n"
        f"Scene description: {scene_prompt}\n\n"
        f"{modification_block}\n"
        "Replace only the placeholder car with the user's vehicle. "
        "Do not clip the vehicle into a platform or circular disc — preserve the full car silhouette. "
        "Match lighting and scale. Do not change the room, perspective, or vehicle design. "
        f"{PRESERVATION_REMINDER}"
    )


def build_extract_user_text(
    *,
    angle: str = "three_quarter_left",
    vehicle_descriptor: dict | None = None,
) -> str:
    """User message for vehicle cutout extraction."""
    identity_block = format_vehicle_identity(vehicle_descriptor, angle=angle)
    modification_block = build_modification_scope(task="extract")

    if angle == "interior":
        task_line = (
            "Extract the car interior cabin visible in this photo. "
            "Return PNG with transparent background outside the cabin glass and body."
        )
    else:
        task_line = (
            "Extract the car from this photo. "
            "Return PNG with transparent background."
        )

    return (
        f"{task_line}\n\n"
        f"{identity_block}\n\n"
        f"{modification_block}\n"
        "Keep every vehicle detail exactly as photographed. "
        f"{PRESERVATION_REMINDER}"
    )


def build_background_environment_prompt(environment: str, *, angle: str) -> str:
    """Environment description for in-place editing — never instruct camera changes."""
    if angle == "interior":
        return (
            f"{environment} "
            "Replace the environment visible outside the cabin windows. "
            "Keep the cabin interior and camera viewpoint exactly as photographed."
        )
    return (
        f"{environment} "
        "Replace ONLY the distant backdrop behind the existing vehicle. "
        f"{INPLACE_BACKDROP_CONSTRAINTS} "
        "Keep the vehicle, original camera angle, perspective, and framing unchanged."
    )


def ensure_prompt_compliance(system_prompt: str, user_prompt: str) -> tuple[str, str]:
    """Verify required preservation markers; append missing fragments if needed."""
    system = system_prompt
    user = user_prompt

    missing_system = [m for m in REQUIRED_SYSTEM_MARKERS if m not in system]
    if missing_system:
        logger.warning("System prompt missing markers %s — appending preservation block", missing_system)
        system = f"{system}\n\n{PRESERVATION_REMINDER}"

    if "SOURCE VEHICLE IDENTITY" not in user:
        logger.warning("User prompt missing vehicle identity block — appending fallback")
        user = f"{format_vehicle_identity(None)}\n\n{user}"

    if "REQUESTED MODIFICATION" not in user:
        logger.warning("User prompt missing modification scope — appending default")
        user = f"{user}\n\n{build_modification_scope(task='background_replace')}"

    if "Preserve every original design feature" not in user:
        user = f"{user}\n\n{PRESERVATION_REMINDER}"

    if not _passes_self_check(system, user):
        user = f"{user}\n\n" + " ".join(MINIMAL_INTERVENTION_PHRASES[:4])

    return system, user


def _passes_self_check(system_prompt: str, user_prompt: str) -> bool:
    combined = f"{system_prompt}\n{user_prompt}".lower()
    checks = (
        "source" in combined and "truth" in combined or "source vehicle identity" in combined,
        "forbidden" in combined or "do not" in combined,
        "requested modification" in combined,
        "preserve" in combined,
    )
    return all(checks)
