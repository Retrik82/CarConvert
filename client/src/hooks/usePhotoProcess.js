import { useCallback, useRef, useState } from "react";
import { getPhotoResult, processPhoto } from "../api/photoApi";

const POLL_INTERVAL = 2000;
const POLL_TIMEOUT = 6 * 60 * 1000;
const MAX_TRANSIENT_ERRORS = 5;
const QUEUED_STALL_POLLS = 15;

export function usePhotoProcess() {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [status, setStatus] = useState("");
  const [statusDetail, setStatusDetail] = useState("");
  const [error, setError] = useState("");
  const pollRef = useRef(null);

  const stopPolling = useCallback(() => {
    if (pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  }, []);

  const pollResult = useCallback(
    (jobId, { onComplete, onUserUpdate, strings } = {}) =>
      new Promise((resolve, reject) => {
        const started = Date.now();
        let queuedCount = 0;
        let transientErrors = 0;
        let pollInFlight = false;

        const tick = async () => {
          if (pollInFlight) return;
          pollInFlight = true;

          if (Date.now() - started > POLL_TIMEOUT) {
            stopPolling();
            setLoading(false);
            const msg = "Processing timed out";
            setError(msg);
            reject(new Error(msg));
            pollInFlight = false;
            return;
          }

          try {
            const result = await getPhotoResult(jobId);
            transientErrors = 0;

            if (result.status === "queued") {
              queuedCount += 1;
              const stalled = queuedCount >= QUEUED_STALL_POLLS;
              setProgress(stalled ? 85 : 15 + Math.min(queuedCount * 2, 25));
              setStatus("queued");
              setStatusDetail(stalled ? strings?.processingStalled || "Still waiting…" : strings?.processingQueued || "Queued");
            } else if (result.status === "processing") {
              queuedCount = 0;
              setProgress((p) => Math.min(p + 8, 85));
              setStatus("processing");
              setStatusDetail(strings?.processingRendering || "Rendering");
            } else if (result.status === "completed" && result.image_base64) {
              stopPolling();
              setProgress(100);
              setLoading(false);
              onUserUpdate?.();
              onComplete?.(result);
              resolve(result);
            } else if (result.status === "failed") {
              stopPolling();
              setLoading(false);
              const msg = result.error || "Processing failed";
              setError(msg);
              reject(new Error(msg));
            } else {
              setProgress((p) => Math.min(p + 4, 90));
              setStatus("processing");
            }
          } catch (e) {
            transientErrors += 1;
            if (transientErrors >= MAX_TRANSIENT_ERRORS) {
              stopPolling();
              setLoading(false);
              setError(e.message);
              reject(e);
            }
          } finally {
            pollInFlight = false;
          }
        };

        pollRef.current = setInterval(tick, POLL_INTERVAL);
        tick();
      }),
    [stopPolling],
  );

  const process = useCallback(
    async (file, { sessionId, background, onComplete, onUserUpdate, strings } = {}) => {
      stopPolling();
      setLoading(true);
      setError("");
      setProgress(5);
      setStatus("uploading");
      setStatusDetail(strings?.processingUploading || "Uploading");

      try {
        const job = await processPhoto(file, { sessionId, background });
        setProgress(12);
        setStatus("queued");
        setStatusDetail(strings?.processingQueued || "Queued");
        return await pollResult(job.job_id, { onComplete, onUserUpdate, strings });
      } catch (e) {
        setLoading(false);
        const msg = e.response?.data?.detail || e.response?.data?.error || e.message;
        setError(typeof msg === "string" ? msg : "Upload failed");
        throw e;
      }
    },
    [pollResult, stopPolling],
  );

  const reset = useCallback(() => {
    stopPolling();
    setLoading(false);
    setProgress(0);
    setStatus("");
    setStatusDetail("");
    setError("");
  }, [stopPolling]);

  return { loading, progress, status, statusDetail, error, setError, process, reset, stopPolling };
}
