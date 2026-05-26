import { useRef } from "react";

const ACCEPTED_TYPES = ["image/jpeg", "image/png", "image/webp"];

export default function UploadDropzone({ file, onFileSelect, disabled }) {
  const inputRef = useRef(null);

  const handleFiles = (files) => {
    if (!files?.length) return;
    const nextFile = files[0];
    if (!ACCEPTED_TYPES.includes(nextFile.type)) {
      onFileSelect(null, "Only JPG, PNG, or WEBP are supported.");
      return;
    }
    if (nextFile.size > 10 * 1024 * 1024) {
      onFileSelect(null, "Max file size is 10MB.");
      return;
    }
    onFileSelect(nextFile, "");
  };

  return (
    <div
      className="group rounded-2xl border border-dashed border-sky-300/40 bg-slate-900/40 p-6 transition hover:border-sky-300/70"
      onDragOver={(e) => e.preventDefault()}
      onDrop={(e) => {
        e.preventDefault();
        if (disabled) return;
        handleFiles(e.dataTransfer.files);
      }}
    >
      <input
        ref={inputRef}
        type="file"
        className="hidden"
        accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
        disabled={disabled}
        onChange={(e) => handleFiles(e.target.files)}
      />
      <button
        type="button"
        disabled={disabled}
        onClick={() => inputRef.current?.click()}
        className="w-full rounded-xl border border-sky-200/20 bg-slate-800/50 px-5 py-4 text-left transition hover:bg-slate-800/80 disabled:cursor-not-allowed disabled:opacity-60"
      >
        <p className="text-sm text-slate-200">
          Drag and drop image here or <span className="text-cyan-300">browse files</span>
        </p>
        <p className="mt-1 text-xs text-slate-400">JPG, PNG, WEBP up to 10MB</p>
        {file ? <p className="mt-2 text-xs text-teal-300">Selected: {file.name}</p> : null}
      </button>
    </div>
  );
}
