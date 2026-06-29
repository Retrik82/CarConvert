/** Studio background thumbnail — ported from background_scene_preview.dart */

import AuthenticatedImage from "../AuthenticatedImage";
import { bundledPresetImagePath, BUNDLED_PRESET_SLUGS } from "../../api/backgroundsApi";
import { IconStudio } from "../ui/Icons";

function resolveBundledSlug(preset) {
  if (BUNDLED_PRESET_SLUGS.includes(preset.slug)) return preset.slug;
  if (preset.id?.startsWith("local-")) {
    const localSlug = preset.id.slice("local-".length);
    if (BUNDLED_PRESET_SLUGS.includes(localSlug)) return localSlug;
  }
  const normalized = (preset.name || "").trim().toLowerCase();
  if (normalized === "gray showroom") return "gray-showroom";
  if (normalized === "auto workshop") return "auto-workshop";
  return null;
}

function sceneSrc(preset, angle) {
  if (!preset) return null;
  const variant = angle
    ? preset.variants?.find((v) => v.angle === angle)
    : preset.variants?.[0];
  const resolvedAngle = variant?.angle || angle || "three_quarter_left";

  const bundledSlug = resolveBundledSlug(preset);
  if (bundledSlug && !preset.is_custom) {
    return `/backgrounds/presets/${bundledSlug}/${resolvedAngle}.jpg`;
  }

  if (variant?.id) {
    const bundled = bundledPresetImagePath(variant.id);
    if (bundled) return bundled;
    return null;
  }

  return preset.preview_url || null;
}

export default function BackgroundScenePreview({ preset, angle, className = "", fit = "cover" }) {
  const src = sceneSrc(preset, angle);
  const fitClass = fit === "contain" ? "object-contain" : "object-cover";

  if (!src) {
    return (
      <div className={`flex h-full w-full items-center justify-center bg-slate-800 ${className}`}>
        <IconStudio className="h-6 w-6 text-brand-400" />
      </div>
    );
  }

  if (src.startsWith("/backgrounds/presets/")) {
    return <img src={src} alt="" className={`h-full w-full ${fitClass} ${className}`} />;
  }

  return (
    <AuthenticatedImage
      src={src}
      alt=""
      className={`h-full w-full ${fitClass} ${className}`}
    />
  );
}

export function resolvePresetFromSelection(selected, presets, custom) {
  if (!selected) return null;
  if (selected.userBackgroundId) {
    return custom.find((p) => p.id === selected.userBackgroundId) || null;
  }
  return presets.find((p) => p.slug === selected.presetSlug || p.id === selected.presetId) || null;
}
