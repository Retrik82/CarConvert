import { useCallback, useRef, useState } from "react";
import { getPhotoResult, processPhoto } from "../api/photoApi";

const POLL_INTERVAL = 2000;
const POLL_TIMEOUT = 6 * 60 * 1000;

export function usePhotoProcess() {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const pollRef = useRef(null);

  const stopPolling = useCallback(() => {
    if (pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  }, []);

  const pollResult = useCallback(
    (jobId, { onComplete, onUserUpdate } = {}) =>
      new Promise((resolve, reject) => {
        const started = Date.now();
        let queuedCount = 0;

        const tick = async () => {
          try {
            const result = await getPhotoResult(jobId);

            if (result.status === "queued") {
              queuedCount += 1;
              setProgress(15 + Math.min(queuedCount * 2, 25));
              setStatus("queued");
            } else if (result.status === "processing") {
              setProgress((p) => Math.min(p + 8, 85));
              setStatus("processing");
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
            }

            if (Date.now() - started > POLL_TIMEOUT) {
              stopPolling();
              setLoading(false);
              const msg = "Processing timed out";
              setError(msg);
              reject(new Error(msg));
            }
          } catch (e) {
            stopPolling();
            setLoading(false);
            setError(e.message);
            reject(e);
          }
        };

        pollRef.current = setInterval(tick, POLL_INTERVAL);
        tick();
      }),
    [stopPolling],
  );

  const process = useCallback(
    async (file, { sessionId, background, onComplete, onUserUpdate } = {}) => {
      stopPolling();
      setLoading(true);
      setError("");
      setProgress(5);
      setStatus("uploading");

      try {
        const job = await processPhoto(file, { sessionId, background });
        setProgress(12);
        setStatus("queued");
        return await pollResult(job.job_id, { onComplete, onUserUpdate });
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
    setError("");
  }, [stopPolling]);

  return { loading, progress, status, error, setError, process, reset, stopPolling };
}
