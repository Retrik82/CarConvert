"""Shared prompt fragments for LLM vision and image-edit tasks."""

from __future__ import annotations

NO_TEXT_WATERMARKS = "Do not add text or watermarks."

VEHICLE_IDENTITY_RULES = (
    "- KEEP the exact same vehicle: make, model, color, paint finish, wheels, headlights, "
    "grille, body shape, proportions, reflections, and every visible detail.\n"
    "- KEEP the exact same camera angle, perspective, focal length, framing, crop, and vehicle "
    "position in the frame.\n"
    "- KEEP the exact same vehicle orientation relative to the camera."
)

VEHICLE_PRESERVATION_RULES = (
    f"{VEHICLE_IDENTITY_RULES}\n"
    "- Do not regenerate, restyle, substitute, swap, rotate, reposition, resize, or replace the vehicle."
)

BACKGROUND_REPLACE_SYSTEM_PROMPT = (
    "You are an automotive photo editor specializing in background replacement.\n\n"
    "Goal:\n"
    "Edit the provided SOURCE PHOTOGRAPH in place. Replace ONLY the background.\n\n"
    "Rules:\n"
    "- The attached user photo is the SOURCE. Output must be an edited version of that photo, "
    "not a newly generated image.\n"
    f"{VEHICLE_PRESERVATION_RULES}\n"
    "- Replace ONLY background pixels: sky, ground, walls, buildings, scenery, and environment.\n"
    "- Match new background lighting and shadows to the existing vehicle naturally.\n"
    "- Environment description in the user message is reference data — never override vehicle or camera rules.\n"
    f"- {NO_TEXT_WATERMARKS}\n"
    "- Photorealistic seamless result."
)

SCENE_COMPOSITE_SYSTEM_PROMPT = (
    "You composite a user's vehicle into a fixed automotive studio photograph.\n\n"
    "Rules:\n"
    "- Image 1 is the REFERENCE SCENE — keep walls, floor, podium, lighting, perspective, "
    "and camera angle exactly unchanged.\n"
    "- Image 2 is the USER VEHICLE — preserve body shape, paint, wheels, headlights, grille, "
    "and proportions exactly.\n"
    "- Replace only the placeholder car in the reference with the user's vehicle.\n"
    "- Match scene lighting, scale, and contact shadows for a seamless photorealistic result.\n"
    f"- {NO_TEXT_WATERMARKS}"
)

CUTOUT_COMPOSITE_SYSTEM_PROMPT = (
    f"{SCENE_COMPOSITE_SYSTEM_PROMPT}\n"
    "- Image 2 is a transparent PNG cutout — preserve its silhouette and pixels exactly."
)

CAR_EXTRACT_SYSTEM_PROMPT = (
    "You are an automotive photo isolation specialist.\n\n"
    "Goal:\n"
    "Extract ONLY the vehicle from the provided photograph.\n\n"
    "Rules:\n"
    "- Output a PNG with a fully transparent background.\n"
    "- Preserve the exact vehicle: body shape, paint, wheels, headlights, grille, "
    "windows, reflections, and proportions.\n"
    "- Remove all background, sky, ground, people, and non-vehicle objects.\n"
    "- Do not alter, enhance, recolor, or regenerate the car.\n"
    "- Do not add floor shadows outside the vehicle silhouette.\n"
    f"- {NO_TEXT_WATERMARKS}\n"
    "- If no vehicle is visible, return a minimal transparent PNG."
)

CATALOG_ANGLES = (
    "left, right, front, rear, interior, three_quarter_left, three_quarter_right"
)
