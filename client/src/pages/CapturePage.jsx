import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { getAuthTokens, getWsBase } from "../api/httpClient";
import { startSession } from "../api/photoApi";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import { getGenerationPrice } from "../api/settingsApi";
import { formatUsd } from "../utils/format";
import UploadDropzone from "../components/UploadDropzone";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

export default function CapturePage() {
  const s = useStrings();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const mode = params.get("mode") === "camera" ? "camera" : "gallery";
  const carId = params.get("carId");
  const { selected } = useBackground();

  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState("");
  const [price, setPrice] = useState(null);
  const [error, setError] = useState("");
  const [cameraOn, setCameraOn] = useState(false);
  const [hint, setHint] = useState(null);
  const [status, setStatus] = useState("");

  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const wsRef = useRef(null);
  const frameTimerRef = useRef(null);
  const sessionIdRef = useRef(null);

  useEffect(() => {
    getGenerationPrice().then(setPrice).catch(() => {});
    return () => stopCamera();
  }, []);

  useEffect(() => {
    if (!file) {
      setPreview("");
      return undefined;
    }
    const url = URL.createObjectURL(file);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  const stopCamera = () => {
    if (frameTimerRef.current) clearInterval(frameTimerRef.current);
    frameTimerRef.current = null;
    wsRef.current?.close();
    wsRef.current = null;
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    setCameraOn(false);
  };

  const startCamera = async () => {
    setError("");
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment", width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false,
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
      }

      const sessionId = await startSession();
      sessionIdRef.current = sessionId;
      const { accessToken } = getAuthTokens();
      const ws = new WebSocket(
        `${getWsBase()}/camera/stream?session_id=${sessionId}&token=${accessToken}`,
      );
      wsRef.current = ws;

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === "connected") {
            setStatus(s.cameraActive);
            return;
          }
          if (data.type === "error") {
            setStatus(data.message);
            return;
          }
          if (data.hint) setHint(data);
        } catch {
          /* ignore */
        }
      };

      ws.onopen = () => setStatus(s.cameraConnecting);

      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");

      frameTimerRef.current = setInterval(() => {
        if (!videoRef.current || !wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) return;
        const video = videoRef.current;
        canvas.width = video.videoWidth || 640;
        canvas.height = video.videoHeight || 480;
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL("image/jpeg", 0.6);
        wsRef.current.send(
          JSON.stringify({
            type: "frame",
            image_base64: dataUrl.split(",")[1],
            mime_type: "image/jpeg",
            timestamp: Date.now(),
          }),
        );
      }, 500);

      setCameraOn(true);
    } catch {
      setError(s.cameraPermission);
    }
  };

  const captureFromCamera = () => {
    const video = videoRef.current;
    if (!video) return;
    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext("2d").drawImage(video, 0, 0);
    canvas.toBlob((blob) => {
      if (!blob) return;
      const captured = new File([blob], `capture-${Date.now()}.jpg`, { type: "image/jpeg" });
      setFile(captured);
      stopCamera();
    }, "image/jpeg", 0.92);
  };

  const handleProcess = () => {
    if (!file) return;
    navigate("/app/processing", {
      state: {
        file,
        sessionId: sessionIdRef.current,
        background: selected,
        carId,
      },
    });
  };

  return (
    <div>
      <PageHeader
        title={s.captureTitle || s.takePhoto}
        subtitle={selected?.displayName}
        action={price != null ? <span className="text-sm text-slate-500">{formatUsd(price)} {s.estimatedPrice}</span> : null}
      />

      {mode === "camera" && !file ? (
        <Card className="mb-6 overflow-hidden p-0">
          <div className="relative aspect-[4/3] bg-slate-900">
            <video ref={videoRef} className="h-full w-full object-cover" playsInline muted />
            {hint?.message ? (
              <div className="absolute inset-x-4 bottom-4 rounded-2xl bg-black/60 px-4 py-3 text-center text-sm text-white backdrop-blur">
                {hint.message}
              </div>
            ) : null}
            {status ? (
              <div className="absolute left-4 top-4 rounded-full bg-black/50 px-3 py-1 text-xs text-white">
                {status}
              </div>
            ) : null}
          </div>
          <div className="flex flex-wrap gap-3 p-4">
            {!cameraOn ? (
              <Button onClick={startCamera}>{s.takePhoto}</Button>
            ) : (
              <Button onClick={captureFromCamera}>{s.capture}</Button>
            )}
          </div>
        </Card>
      ) : (
        <div className="mb-6">
          <UploadDropzone file={file} onFileSelect={(f, msg) => (msg ? setError(msg) : (setError(""), setFile(f)))} />
        </div>
      )}

      {preview ? (
        <Card className="mb-6 overflow-hidden p-0">
          <img src={preview} alt="Preview" className="max-h-96 w-full object-contain bg-slate-50" />
        </Card>
      ) : null}

      <div className="flex flex-wrap gap-3">
        <Button disabled={!file} onClick={handleProcess}>
          {s.processingTitle}
        </Button>
        <Button variant="secondary" onClick={() => navigate(-1)}>
          {s.cancel}
        </Button>
      </div>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
