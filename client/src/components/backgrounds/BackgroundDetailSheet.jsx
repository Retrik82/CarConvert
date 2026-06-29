/** Background detail bottom sheet — ported from openBackgroundDetailSheet */

import { useStrings } from "../../contexts/SettingsContext";
import BackgroundScenePreview from "../capture/BackgroundScenePreview";
import BackgroundPreviewGrid from "./BackgroundPreviewGrid";
import Button from "../ui/Button";
import Modal from "../ui/Modal";

export function BackgroundDetailModal({ open, preset, isSelected, onClose, onSelect, onAngleTap }) {
  const s = useStrings();
  if (!preset) return null;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={preset.name}
      wide
      footer={
        <Button className="w-full" onClick={onSelect}>
          {isSelected ? s.useThisBackground : s.selectBackground}
        </Button>
      }
    >
      {preset.description ? (
        <p className="mb-4 text-sm text-ink-secondary">{preset.description}</p>
      ) : null}
      {preset.generation_prompt ? (
        <div className="mb-4 rounded-2xl border border-slate-100 bg-surface-muted p-3">
          <p className="mb-2 text-xs font-semibold text-ink">{s.backgroundGenerationPrompt}</p>
          <p className="text-sm leading-relaxed text-ink-secondary">{preset.generation_prompt}</p>
        </div>
      ) : null}
      <h3 className="mb-3 font-semibold text-ink">{s.backgroundAnglesTitle}</h3>
      <BackgroundPreviewGrid preset={preset} onAngleTap={onAngleTap} />
    </Modal>
  );
}

export function BackgroundAngleFullscreen({ open, preset, angle, onClose }) {
  const s = useStrings();
  if (!open || !preset || !angle) return null;

  return (
    <div className="fixed inset-0 z-[60] flex flex-col bg-black">
      <div className="flex items-center justify-between px-4 py-3 text-white">
        <button type="button" onClick={onClose} className="text-sm font-medium">
          {s.cancel}
        </button>
        <p className="text-sm">
          {preset.name} · {angle.replaceAll("_", " ")}
        </p>
        <span className="w-12" />
      </div>
      <div className="flex flex-1 items-center justify-center overflow-hidden p-4">
        <div className="aspect-video w-full max-w-4xl overflow-hidden rounded-2xl">
          <BackgroundScenePreview preset={preset} angle={angle} fit="contain" />
        </div>
      </div>
      <p className="pb-6 text-center text-xs text-white/60">{s.pinchToZoom}</p>
    </div>
  );
}
