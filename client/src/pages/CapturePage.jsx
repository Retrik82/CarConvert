import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { ArrowLeft, Image as ImageIcon, Loader2 } from "lucide-react";
import { getAuthTokens, getWsBase } from "../api/httpClient";
import { startSession } from "../api/photoApi";
import { getGenerationPrice } from "../api/settingsApi";
import { useAuth } from "../contexts/AuthContext";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import CaptureHintBar from "../components/capture/CaptureHintBar";
import FrameGuideOverlay from "../components/capture/FrameGuideOverlay";
import QualityIndicators from "../components/capture/QualityIndicators";
import BackgroundScenePreview, {
  resolvePresetFromSelection,
} from "../components/capture/BackgroundScenePreview";
import UploadDropzone from "../components/UploadDropzone";
import Toast from "../components/ui/Toast";
import { parseHintResponse, framingScore, lightingScore, focusScore } from "../models/hintResponse";
import { resolveHintMessage } from "../utils/hintLocalizer";
import { cropToFrameGuide, frameCropForSize, frameCropForViewport } from "../utils/frameCrop";
import { formatUsd } from "../utils/format";
import { captureChrome } from "../theme/captureChrome";

const FRAME_INTERVAL_MS = 500;

export default function CapturePage() {
  const s = useStrings();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const initialMode = params.get("mode") === "gallery" ? "gallery" : "camera";
  const carId = params.get("carId");
  const { user, refreshUser } = useAuth();
  const { selected, presets, custom } = useBackground();

  const [mode, setMode] = useState(initialMode);
  const [price, setPrice] = useState(null);
  const [error, setError] = useState("");
  const [hint, setHint] = useState(null);
  const [status, setStatus] = useState("Initializing...");
  const [cameraReady, setCameraReady] = useState(false);
  const [capturing, setCapturing] = useState(false);
  const [viewportSize, setViewportSize] = useState({ w: 0, h: 0 });

  const videoRef = useRef(null);
  const viewportRef = useRef(null);
  const streamRef = useRef(null);
  const wsRef = useRef(null);
  const frameTimerRef = useRef(null);
  const sessionIdRef = useRef(null);
  const reconnectRef = useRef(0);

  const selectedPreset = useMemo(
    () => resolvePresetFromSelection(selected, presets, custom),
    [selected, presets, custom],
  );

  const frameCrop = useMemo(() => {
    if (viewportSize.w && viewportSize.h) return frameCropForSize(viewportSize.w, viewportSize.h);
    return frameCropForViewport();
  }, [viewportSize]);

  const isPerfect = hint?.isPerfect === true;
  const hintMessage = resolveHintMessage(s, hint, status);
  const arrowDirection = hint?.overlay?.arrow || "none";

  const stopCamera = useCallback(() => {
    if (frameTimerRef.current) clearInterval(frameTimerRef.current);
    frameTimerRef.current = null;
    wsRef.current?.close();
    wsRef.current = null;
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    setCameraReady(false);
  }, []);

  const connectWs = useCallback(
    (sessionId) => {
      const { accessToken } = getAuthTokens();
      const ws = new WebSocket(
        `${getWsBase()}/camera/stream?session_id=${sessionId}&token=${accessToken}`,
      );
      wsRef.current = ws;

      ws.onopen = () => setStatus(s.cameraConnecting);
      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === "connected") {
            setStatus(s.cameraActive);
            reconnectRef.current = 0;
            return;
          }
          if (data.type === "error") {
            setStatus(data.message || s.errorGeneric);
            return;
          }
          const parsed = parseHintResponse(data);
          if (parsed) setHint(parsed);
        } catch {
          /* ignore */
        }
      };
      ws.onclose = () => {
        if (mode !== "camera" || !streamRef.current) return;
        if (reconnectRef.current < 3 && sessionIdRef.current) {
          reconnectRef.current += 1;
          setTimeout(() => connectWs(sessionIdRef.current), 1000);
        } else {
          setStatus(s.errorGeneric);
        }
      };
    },
    [mode, s],
  );

  const startFrameStream = useCallback(() => {
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");

    frameTimerRef.current = setInterval(() => {
      const video = videoRef.current;
      const ws = wsRef.current;
      if (!video || !ws || ws.readyState !== WebSocket.OPEN) return;
      canvas.width = video.videoWidth || 640;
      canvas.height = video.videoHeight || 480;
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const dataUrl = canvas.toDataURL("image/jpeg", 0.6);
      ws.send(
        JSON.stringify({
          type: "frame",
          image_base64: dataUrl.split(",")[1],
          mime_type: "image/jpeg",
          timestamp: Date.now(),
        }),
      );
    }, FRAME_INTERVAL_MS);
  }, []);

  const initCamera = useCallback(async () => {
    setError("");
    setStatus("Initializing...");
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
      connectWs(sessionId);
      startFrameStream();
      setCameraReady(true);
      setStatus(s.cameraConnecting);
    } catch {
      setError(s.cameraPermission);
      setStatus(s.cameraPermission);
    }
  }, [connectWs, s, startFrameStream]);

  useEffect(() => {
    getGenerationPrice().then(setPrice).catch(() => {});
    refreshUser().catch(() => {});
    return () => stopCamera();
  }, [refreshUser, stopCamera]);

  useEffect(() => {
    if (mode === "camera") initCamera();
    else stopCamera();
  }, [mode, initCamera, stopCamera]);

  useEffect(() => {
    const el = viewportRef.current;
    if (!el) return undefined;
    const ro = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect;
      setViewportSize({ w: width, h: height });
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, [mode]);

  const checkBalance = useCallback(() => {
    if (price == null || user == null) return true;
    if (user.balance < price) {
      setError(s.insufficientBalance);
      return false;
    }
    return true;
  }, [price, user, s]);

  const goToProcessing = useCallback(
    (file) => {
      navigate("/app/processing", {
        state: {
          file,
          sessionId: sessionIdRef.current,
          background: selected,
          carId,
        },
      });
    },
    [navigate, selected, carId],
  );

  const capturePhoto = async () => {
    if (!videoRef.current || capturing) return;
    if (!checkBalance()) return;

    setCapturing(true);
    try {
      const cropped = await cropToFrameGuide(videoRef.current, frameCrop);
      goToProcessing(cropped);
    } catch {
      setError(s.errorGeneric);
    } finally {
      setCapturing(false);
    }
  };

  const handleGalleryFile = async (file, msg) => {
    if (msg) {
      setError(msg);
      return;
    }
    if (!file) return;
    if (!checkBalance()) return;

    setCapturing(true);
    try {
      const cropped = await cropToFrameGuide(file, frameCropForViewport());
      goToProcessing(cropped);
    } catch {
      setError(s.errorGeneric);
    } finally {
      setCapturing(false);
    }
  };

  if (mode === "gallery") {
    return (
      <div className="page-enter mx-auto max-w-lg py-4">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="mb-4 flex items-center gap-2 text-sm font-medium text-ink-secondary hover:text-ink"
        >
          <ArrowLeft className="h-4 w-4" />
          {s.cancel}
        </button>
        <h1 className="mb-2 text-2xl font-bold text-ink">{s.fromGallery}</h1>
        <p className="mb-6 text-sm text-ink-secondary">{s.selectGalleryPhoto}</p>
        <UploadDropzone file={null} onFileSelect={handleGalleryFile} />
        {capturing ? (
          <div className="mt-6 flex items-center justify-center gap-2 text-sm text-ink-secondary">
            <Loader2 className="h-4 w-4 animate-spin" />
            {s.processingUploading}
          </div>
        ) : null}
        <button
          type="button"
          className="mt-6 text-sm font-medium text-brand-600"
          onClick={() => setMode("camera")}
        >
          {s.takePhoto}
        </button>
        <Toast message={error} onClose={() => setError("")} />
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black" style={{ color: captureChrome.textPrimary }}>
      {/* Top gradient + bar */}
      <div
        className="absolute inset-x-0 top-0 z-20 bg-gradient-to-b from-black/70 via-black/35 to-transparent"
        style={{ paddingTop: "env(safe-area-inset-top)" }}
      >
        <div className="flex items-center gap-2 px-3 py-2">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/20 bg-white/10"
            aria-label={s.cancel}
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <h1 className="flex-1 text-center text-base font-semibold">{s.captureTitle}</h1>
          <button
            type="button"
            onClick={() => navigate("/app/backgrounds")}
            className="h-12 w-12 overflow-hidden rounded-xl border border-brand-500/40 shadow-[0_0_8px_rgba(37,99,235,0.4)]"
            aria-label={s.chooseBackground}
          >
            {selectedPreset ? (
              <BackgroundScenePreview preset={selectedPreset} className="h-full w-full" />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-slate-800 text-brand-400">
                <ImageIcon className="h-5 w-5" />
              </div>
            )}
          </button>
        </div>
        {price != null ? (
          <p className="pb-2 text-center text-xs" style={{ color: captureChrome.textMuted }}>
            {formatUsd(price)} · {s.estimatedPrice}
          </p>
        ) : null}
      </div>

      {/* Camera viewport */}
      <div ref={viewportRef} className="relative flex-1 overflow-hidden bg-black">
        {cameraReady ? (
          <video ref={videoRef} className="h-full w-full object-cover" playsInline muted autoPlay />
        ) : (
          <div className="flex h-full flex-col items-center justify-center gap-4">
            <Loader2 className="h-8 w-8 animate-spin text-brand-500" />
            <p className="text-sm" style={{ color: captureChrome.textMuted }}>
              {status === "Initializing..." ? s.advisorConnecting : status}
            </p>
          </div>
        )}
        {cameraReady ? <FrameGuideOverlay crop={frameCrop} isPerfect={isPerfect} /> : null}

        {/* Floating hint */}
        {cameraReady ? (
          <div className="absolute inset-x-4 bottom-36 z-10">
            <CaptureHintBar
              message={hintMessage}
              isPerfect={isPerfect}
              arrowDirection={arrowDirection}
              floating
            />
          </div>
        ) : null}

        {/* Quality scores */}
        {cameraReady && hint ? (
          <div className="absolute right-3 top-24 z-10 hidden w-44 sm:block">
            <QualityIndicators
              framingScore={framingScore(hint)}
              lightingScore={lightingScore(hint)}
              focusScore={focusScore(hint)}
              labels={{
                framing: s.qualityFraming,
                lighting: s.qualityLighting,
                focus: s.qualityFocus,
              }}
            />
          </div>
        ) : null}

        {/* Status pill */}
        {cameraReady && status ? (
          <div className="absolute left-4 top-24 z-10 rounded-full bg-black/50 px-3 py-1 text-xs text-white">
            {status}
          </div>
        ) : null}
      </div>

      {/* Bottom controls */}
      <div
        className="relative z-20 bg-gradient-to-t from-black/90 via-black/45 to-transparent px-6 pb-6 pt-4"
        style={{ paddingBottom: "max(1.5rem, env(safe-area-inset-bottom))" }}
      >
        <div className="flex items-center justify-center gap-8">
          <button
            type="button"
            onClick={() => setMode("gallery")}
            className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/20 bg-white/10"
            aria-label={s.fromGallery}
          >
            <ImageIcon className="h-5 w-5" />
          </button>

          <button
            type="button"
            disabled={!cameraReady || capturing}
            onClick={capturePhoto}
            className="relative flex h-[72px] w-[72px] items-center justify-center rounded-full border-[3px] transition-all disabled:opacity-50"
            style={{
              borderColor: isPerfect ? captureChrome.perfect : captureChrome.accent,
              boxShadow: `0 0 16px ${isPerfect ? captureChrome.perfectGlow : captureChrome.accentGlow}`,
            }}
            aria-label={s.capture}
          >
            {capturing ? (
              <Loader2 className="h-6 w-6 animate-spin text-brand-400" />
            ) : (
              <span
                className="block h-[58px] w-[58px] rounded-full"
                style={{
                  background: isPerfect
                    ? captureChrome.perfect
                    : "linear-gradient(135deg, #2563EB, #7C3AED)",
                }}
              />
            )}
          </button>

          <div className="h-12 w-12" aria-hidden />
        </div>
      </div>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
