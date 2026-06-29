/** Pinch/zoom image viewer — ported from zoomable_image.dart */

import { useEffect, useRef, useState } from "react";
import { ZoomIn } from "lucide-react";
import { fetchAuthenticatedBlob } from "../api/httpClient";
import { useStrings } from "../contexts/SettingsContext";

export default function ZoomableImage({ src, alt = "", showHint = true, className = "" }) {
  const s = useStrings();
  const [scale, setScale] = useState(1);

  return (
    <div className={`relative overflow-hidden bg-slate-900/95 ${className}`}>
      <div
        className="flex h-full min-h-[240px] w-full items-center justify-center overflow-auto"
        onWheel={(e) => {
          e.preventDefault();
          setScale((s) => Math.min(4, Math.max(1, s - e.deltaY * 0.002)));
        }}
      >
        <img
          src={src}
          alt={alt}
          className="max-h-full max-w-full object-contain transition-transform duration-150"
          style={{ transform: `scale(${scale})` }}
          draggable={false}
        />
      </div>
      {showHint ? (
        <div className="pointer-events-none absolute inset-x-0 bottom-3 flex justify-center">
          <span className="inline-flex items-center gap-1.5 rounded-xl bg-black/45 px-3 py-1.5 text-[11px] font-medium text-white/80">
            <ZoomIn className="h-3.5 w-3.5" />
            {s.pinchToZoom}
          </span>
        </div>
      ) : null}
    </div>
  );
}

export function FullscreenImageModal({ open, src, title, onClose }) {
  const s = useStrings();
  const [blobUrl, setBlobUrl] = useState(null);
  const urlRef = useRef(null);

  useEffect(() => {
    if (!open || !src) return undefined;
    let cancelled = false;

    (async () => {
      try {
        let url = src;
        if (src.startsWith("/") || src.includes("/api/")) {
          const path = src.replace(/^https?:\/\/[^/]+/, "");
          url = await fetchAuthenticatedBlob(path);
        }
        if (cancelled) {
          if (url.startsWith("blob:")) URL.revokeObjectURL(url);
          return;
        }
        if (urlRef.current) URL.revokeObjectURL(urlRef.current);
        urlRef.current = url.startsWith("blob:") ? url : null;
        setBlobUrl(url);
      } catch {
        if (!cancelled) setBlobUrl(null);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [open, src]);

  useEffect(
    () => () => {
      if (urlRef.current) URL.revokeObjectURL(urlRef.current);
    },
    [],
  );

  if (!open || !src) return null;

  return (
    <div className="fixed inset-0 z-[70] flex flex-col bg-black">
      <div className="flex items-center justify-between px-4 py-3 text-white">
        <button type="button" onClick={onClose} className="text-sm font-medium">
          {s.cancel}
        </button>
        {title ? <p className="text-sm">{title}</p> : <span />}
        <span className="w-12" />
      </div>
      {blobUrl ? <ZoomableImage src={blobUrl} className="flex-1" /> : (
        <div className="flex flex-1 items-center justify-center text-white/60">{s.loading}</div>
      )}
    </div>
  );
}
