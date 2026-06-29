import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { usePhotoProcess } from "../hooks/usePhotoProcess";
import LoadingOverlay from "../components/ui/LoadingOverlay";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

export default function ProcessingPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const location = useLocation();
  const { refreshUser } = useAuth();
  const { loading, progress, status, error, setError, process } = usePhotoProcess();

  const { file, sessionId, background, carId } = location.state || {};

  useEffect(() => {
    if (!file) {
      navigate("/app/capture", { replace: true });
      return;
    }

    (async () => {
      try {
        const result = await process(file, {
          sessionId,
          background,
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
  }, []);

  const statusLabel =
    status === "queued"
      ? s.processingQueued
      : status === "processing"
        ? s.processingRendering
        : s.processingUploading;

  return (
    <div>
      <PageHeader title={s.processingTitle} />
      <Card className="relative min-h-[280px]">
        <LoadingOverlay active={loading} progress={progress} label={statusLabel} />
        <p className="text-center text-sm text-ink-secondary">{statusLabel}</p>
      </Card>
      <Toast message={error} onClose={() => setError("")} />
      {error ? (
        <button
          type="button"
          className="mt-4 text-sm font-medium text-brand-600"
          onClick={() => navigate("/app/capture")}
        >
          {s.retry}
        </button>
      ) : null}
    </div>
  );
}
