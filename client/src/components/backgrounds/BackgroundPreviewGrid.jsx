/** 7-angle preview grid — ported from background_preview_grid.dart */

import BackgroundScenePreview from "../capture/BackgroundScenePreview";

export const PREVIEW_ANGLES = [
  "three_quarter_left",
  "three_quarter_right",
  "left",
  "right",
  "front",
  "rear",
  "interior",
];

function angleLabel(angle) {
  return angle.replaceAll("_", " ");
}

export default function BackgroundPreviewGrid({ preset, onAngleTap }) {
  return (
    <div className="grid grid-cols-2 gap-3">
      {PREVIEW_ANGLES.map((angle) => (
        <button
          key={angle}
          type="button"
          onClick={() => onAngleTap?.(angle)}
          className="group relative aspect-video overflow-hidden rounded-2xl bg-surface-muted text-left"
        >
          <BackgroundScenePreview preset={preset} angle={angle} />
          <span className="absolute bottom-2 left-2 rounded-lg bg-black/55 px-2 py-1 text-[11px] font-semibold capitalize text-white">
            {angleLabel(angle)}
          </span>
        </button>
      ))}
    </div>
  );
}
