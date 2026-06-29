import { useRef, useState } from "react";
import { useStrings } from "../contexts/SettingsContext";

const MAX_BYTES = 15 * 1024 * 1024;
const ACCEPT = ["image/jpeg", "image/png", "image/webp"];

export default function UploadDropzone({ file, onFileSelect, disabled, compact = false }) {
  const s = useStrings();
  const inputRef = useRef(null);
  const [dragOver, setDragOver] = useState(false);

  const validate = (nextFile) => {
    if (!nextFile) return null;
    if (!ACCEPT.includes(nextFile.type)) return "Only JPEG, PNG or WebP images are supported.";
    if (nextFile.size > MAX_BYTES) return "Image must be under 15 MB.";
    return null;
  };

  const handleFile = (nextFile) => {
    const message = validate(nextFile);
    onFileSelect(nextFile, message);
  };

  return (
    <div
      className={[
        "relative rounded-card border-2 border-dashed transition",
        dragOver ? "border-brand-400 bg-brand-50/50" : "border-[var(--border)] bg-surface-muted/60",
        disabled ? "pointer-events-none opacity-50" : "cursor-pointer hover:border-brand-300 hover:bg-brand-50/30",
        compact ? "p-4" : "p-8",
      ].join(" ")}
      onDragOver={(e) => {
        e.preventDefault();
        setDragOver(true);
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={(e) => {
        e.preventDefault();
        setDragOver(false);
        handleFile(e.dataTransfer.files?.[0]);
      }}
      onClick={() => inputRef.current?.click()}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") inputRef.current?.click();
      }}
    >
      <input
        ref={inputRef}
        type="file"
        accept={ACCEPT.join(",")}
        className="hidden"
        disabled={disabled}
        onChange={(e) => handleFile(e.target.files?.[0])}
      />

      <div className="flex flex-col items-center text-center">
        <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-white text-xl shadow-sm">
          📷
        </div>
        <p className="text-sm font-medium text-ink">{s.dropPhoto}</p>
        <p className="mt-1 text-xs text-ink-secondary">{s.maxFileSize}</p>
        {file ? (
          <p className="mt-3 rounded-full bg-white px-3 py-1 text-xs font-medium text-brand-700 shadow-sm">
            {file.name}
          </p>
        ) : null}
      </div>
    </div>
  );
}
