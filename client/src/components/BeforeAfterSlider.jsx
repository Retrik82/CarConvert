import { useCallback, useRef, useState } from "react";
import { useStrings } from "../contexts/SettingsContext";

export default function BeforeAfterSlider({
  beforeUrl,
  afterUrl,
  beforeLabel,
  afterLabel,
  className = "",
}) {
  const s = useStrings();
  const containerRef = useRef(null);
  const [position, setPosition] = useState(50);
  const dragging = useRef(false);

  const updatePosition = useCallback((clientX) => {
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = ((clientX - rect.left) / rect.width) * 100;
    setPosition(Math.min(98, Math.max(2, x)));
  }, []);

  const onPointerDown = (e) => {
    dragging.current = true;
    updatePosition(e.clientX);
    e.currentTarget.setPointerCapture(e.pointerId);
  };

  const onPointerMove = (e) => {
    if (!dragging.current) return;
    updatePosition(e.clientX);
  };

  const onPointerUp = () => {
    dragging.current = false;
  };

  return (
    <div
      ref={containerRef}
      className={`relative aspect-[16/10] overflow-hidden rounded-3xl bg-slate-100 shadow-inner ${className}`}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
    >
      {afterUrl ? (
        <img src={afterUrl} alt={afterLabel || s.afterLabel} className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-br from-slate-200 to-slate-300" />
      )}

      <div className="absolute inset-0 overflow-hidden" style={{ width: `${position}%` }}>
        {beforeUrl ? (
          <img
            src={beforeUrl}
            alt={beforeLabel || s.beforeLabel}
            className="h-full w-full max-w-none object-cover"
            style={{ width: containerRef.current?.offsetWidth || "100%" }}
          />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-amber-100 to-orange-200" />
        )}
      </div>

      <div className="pointer-events-none absolute inset-y-0 z-10" style={{ left: `${position}%` }}>
        <div className="relative -ml-px h-full w-0.5 bg-white shadow-lg" />
        <div className="absolute left-1/2 top-1/2 flex h-10 w-10 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-2 border-white bg-white/90 shadow-lg backdrop-blur">
          <span className="text-slate-600">↔</span>
        </div>
      </div>

      <div className="pointer-events-none absolute bottom-3 left-3 rounded-full bg-black/50 px-3 py-1 text-xs font-medium text-white backdrop-blur">
        {beforeLabel || s.beforeLabel}
      </div>
      <div className="pointer-events-none absolute bottom-3 right-3 rounded-full bg-black/50 px-3 py-1 text-xs font-medium text-white backdrop-blur">
        {afterLabel || s.afterLabel}
      </div>
    </div>
  );
}
