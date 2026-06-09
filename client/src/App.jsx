import { useEffect, useMemo, useState } from "react";
import BeforeAfterPreview from "./components/BeforeAfterPreview";
import LoadingOverlay from "./components/LoadingOverlay";
import Toast from "./components/Toast";
import UploadDropzone from "./components/UploadDropzone";
import { useImageEdit } from "./hooks/useImageEdit";
import { downloadBase64Image } from "./utils/download";

export default function App() {
  const [file, setFile] = useState(null);
  const [prompt, setPrompt] = useState("");
  const {
    loading,
    progress,
    error,
    resultBase64,
    resultMime,
    setError,
    clearResult,
    reset,
    generate,
  } = useImageEdit();

  const sourcePreview = useMemo(() => {
    if (!file) return "";
    return URL.createObjectURL(file);
  }, [file]);

  useEffect(() => {
    return () => {
      if (sourcePreview) {
        URL.revokeObjectURL(sourcePreview);
      }
    };
  }, [sourcePreview]);

  const resultPreview = useMemo(() => {
    if (!resultBase64) return "";
    return `data:${resultMime};base64,${resultBase64}`;
  }, [resultBase64, resultMime]);

  const handleFileSelect = (nextFile, message) => {
    if (message) {
      setError(message);
      return;
    }
    setError("");
    setFile(nextFile);
    clearResult();
  };

  const handleGenerate = async () => {
    await generate({ file, prompt });
  };

  const handleReset = () => {
    setFile(null);
    setPrompt("");
    reset();
  };

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-6xl items-center px-4 py-8 sm:px-6 lg:px-8">
      <section className="relative w-full rounded-3xl border border-slate-300/15 bg-panel p-5 shadow-glow backdrop-blur-2xl sm:p-8">
        <LoadingOverlay active={loading} progress={progress} />

        <div className="mb-6 flex flex-col justify-between gap-2 sm:flex-row sm:items-end">
          <div>
            <h1 className="text-2xl font-semibold text-white sm:text-3xl">Car Background Replacer</h1>
          </div>
        </div>

        <div className="grid gap-5 lg:grid-cols-[1fr_1.2fr]">
          <div className="space-y-4">
            <UploadDropzone file={file} onFileSelect={handleFileSelect} disabled={loading} />

            <label className="block">
              <span className="mb-2 block text-sm text-slate-200">Background prompt</span>
              <textarea
                value={prompt}
                disabled={loading}
                onChange={(e) => setPrompt(e.target.value)}
                rows={5}
                placeholder="Example: Golden hour desert road with cinematic mountains in the distance"
                className="w-full resize-none rounded-2xl border border-slate-600/70 bg-slate-900/60 px-4 py-3 text-sm text-slate-100 outline-none ring-cyan-300/40 transition focus:ring"
              />
            </label>

            <div className="flex flex-wrap gap-3">
              <button
                type="button"
                onClick={handleGenerate}
                disabled={loading}
                className="rounded-xl bg-gradient-to-r from-cyan-500 to-teal-400 px-5 py-2.5 text-sm font-medium text-slate-950 transition hover:brightness-105 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Generate
              </button>
              {resultBase64 ? (
                <button
                  type="button"
                  onClick={() => downloadBase64Image(resultBase64, resultMime)}
                  className="rounded-xl border border-sky-300/50 bg-slate-900/50 px-5 py-2.5 text-sm text-sky-200 transition hover:bg-slate-800"
                >
                  Download result
                </button>
              ) : null}
              {(file || resultBase64) && !loading ? (
                <button
                  type="button"
                  onClick={handleReset}
                  className="rounded-xl border border-slate-500/70 bg-slate-900/40 px-5 py-2.5 text-sm text-slate-200 transition hover:bg-slate-800"
                >
                  Generate another
                </button>
              ) : null}
            </div>
          </div>

          <BeforeAfterPreview beforeUrl={sourcePreview} afterUrl={resultPreview} />
        </div>
      </section>

      <Toast message={error} onClose={() => setError("")} />
    </main>
  );
}
