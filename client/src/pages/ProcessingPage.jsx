import { useEffect, useMemo } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { usePhotoProcess } from "../hooks/usePhotoProcess";
import Button from "../components/ui/Button";
import Toast from "../components/ui/Toast";

export default function ProcessingPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const location = useLocation();
  const { refreshUser } = useAuth();
  const { loading, progress, status, statusDetail, error, setError, process } = usePhotoProcess();

  const { file, sessionId, background, carId } = location.state || {};

  const previewUrl = useMemo(() => {
    if (!file) return "";
    return URL.createObjectURL(file);
  }, [file]);

  useEffect(() => {
    if (!file) {
      navigate("/app/capture", { replace: true });
      return undefined;
    }

    (async () => {
      try {
        const result = await process(file, {
          sessionId,
          background,
          strings: s,
          onUserUpdate: refreshUser,
        });
        navigate("/app/result", {
          replace: true,
          state: {
            result,
            file,
            carId,
            previewUrl: URL.createObjectURL(file),
          },
        });
      } catch {
        /* error handled in hook */
      }
    })();

    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, []);

  const statusLabel =
    status === "queued"
      ? s.processingQueued
      : status === "processing"
        ? s.processingRendering
        : s.processingUploading;

  return (
    <div className="page-enter flex min-h-[70vh] flex-col">
      <h1 className="mb-6 text-center text-2xl font-bold text-ink">{s.processingTitle}</h1>

      <div className="relative mx-auto w-full max-w-lg flex-1">
        <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-slate-900 shadow-elevated">
          {previewUrl ? (
            <img src={previewUrl} alt="" className="aspect-[4/3] w-full object-contain" />
          ) : null}
          {loading && !error ? (
            <div className="absolute inset-0 flex items-center justify-center bg-black/35">
              <div className="relative h-20 w-20">
                <svg className="h-20 w-20 -rotate-90" viewBox="0 0 80 80">
                  <circle cx="40" cy="40" r="34" fill="none" stroke="rgba(255,255,255,0.2)" strokeWidth="6" />
                  <circle
                    cx="40"
                    cy="40"
                    r="34"
                    fill="none"
                    stroke="white"
                    strokeWidth="6"
                    strokeDasharray={`${(progress / 100) * 213.6} 213.6`}
                    strokeLinecap="round"
                  />
                </svg>
              </div>
            </div>
          ) : null}
          {error ? (
            <div className="absolute inset-0 flex items-center justify-center bg-red-500/15 text-red-600">
              !
            </div>
          ) : null}
        </div>
      </div>

      <div className="mx-auto mt-8 w-full max-w-lg text-center">
        <p className="text-xl font-bold text-ink">{error ? s.errorGeneric : statusLabel}</p>
        {!error ? (
          <>
            <div className="mx-auto mt-4 h-2 max-w-xs overflow-hidden rounded-full bg-surface-muted">
              <div
                className="h-full rounded-full bg-brand-600 transition-all"
                style={{ width: `${progress}%` }}
              />
            </div>
            <p className="mt-2 text-sm text-ink-secondary">{Math.round(progress)}%</p>
          </>
        ) : null}
        <p className="mt-3 text-sm text-ink-tertiary">{statusDetail || statusLabel}</p>
        {error ? (
          <Button className="mt-6" variant="secondary" onClick={() => navigate("/app/capture")}>
            {s.retry}
          </Button>
        ) : null}
      </div>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
