import { useCallback, useRef, useState } from "react";
import { useStrings } from "../contexts/SettingsContext";

const DEFAULT_BEFORE = "/images/before-street.jpg";
const DEFAULT_AFTER = "/images/after-showroom.jpg";

export default function BeforeAfterSlider({
  beforeUrl = DEFAULT_BEFORE,
  afterUrl = DEFAULT_AFTER,
  beforeLabel,
  afterLabel,
  className = "",
}) {
  const s = useStrings();
  const containerRef = useRef(null);
  const [position, setPosition] = useState(50);
  const [loaded, setLoaded] = useState({ before: false, after: false });
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

  const allLoaded = loaded.before && loaded.after;

  return (
    <div
      ref={containerRef}
      className={`relative aspect-[16/10] overflow-hidden rounded-card bg-surface-muted shadow-card ${className}`}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
      role="img"
      aria-label={`${beforeLabel || s.beforeLabel} / ${afterLabel || s.afterLabel}`}
    >
      {!allLoaded ? (
        <div className="absolute inset-0 skeleton rounded-card" aria-hidden="true" />
      ) : null}

      <img
        src={afterUrl}
        alt={afterLabel || s.afterLabel}
        className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-500 ${loaded.after ? "opacity-100" : "opacity-0"}`}
        loading="lazy"
        decoding="async"
        onLoad={() => setLoaded((p) => ({ ...p, after: true }))}
      />

      <div className="absolute inset-0 overflow-hidden" style={{ width: `${position}%` }}>
        <img
          src={beforeUrl}
          alt={beforeLabel || s.beforeLabel}
          className={`h-full w-full max-w-none object-cover transition-opacity duration-500 ${loaded.before ? "opacity-100" : "opacity-0"}`}
          style={{ width: containerRef.current?.offsetWidth || "100%" }}
          loading="lazy"
          decoding="async"
          onLoad={() => setLoaded((p) => ({ ...p, before: true }))}
        />
      </div>

      <div className="pointer-events-none absolute inset-y-0 z-10" style={{ left: `${position}%` }}>
        <div className="relative -ml-px h-full w-0.5 bg-white shadow-lg" />
        <div className="absolute left-1/2 top-1/2 flex h-11 w-11 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-2 border-white bg-white/95 shadow-elevated backdrop-blur">
          <svg className="h-4 w-4 text-ink-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M8 9l4-4 4 4m0 6l-4 4-4-4" />
          </svg>
        </div>
      </div>

      <div className="pointer-events-none absolute bottom-3 left-3 rounded-full bg-ink/60 px-3 py-1 text-xs font-medium text-white backdrop-blur">
        {beforeLabel || s.beforeLabel}
      </div>
      <div className="pointer-events-none absolute bottom-3 right-3 rounded-full bg-ink/60 px-3 py-1 text-xs font-medium text-white backdrop-blur">
        {afterLabel || s.afterLabel}
      </div>
    </div>
  );
}
