import { useCallback, useEffect, useRef, useState } from "react";
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
  const dragging = useRef(false);
  const [position, setPosition] = useState(50);
  const [loaded, setLoaded] = useState({ before: false, after: false });
  const [containerWidth, setContainerWidth] = useState(0);
  const [isDragging, setIsDragging] = useState(false);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return undefined;

    const measure = () => setContainerWidth(el.getBoundingClientRect().width);
    measure();

    const ro = new ResizeObserver(() => measure());
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const updatePosition = useCallback((clientX) => {
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect?.width) return;
    const x = ((clientX - rect.left) / rect.width) * 100;
    setPosition(Math.min(98, Math.max(2, x)));
  }, []);

  const onPointerDown = (e) => {
    if (e.button !== 0) return;
    dragging.current = true;
    setIsDragging(true);
    updatePosition(e.clientX);
    e.currentTarget.setPointerCapture(e.pointerId);
  };

  const onPointerMove = (e) => {
    if (!dragging.current) return;
    updatePosition(e.clientX);
  };

  const endDrag = (e) => {
    if (!dragging.current) return;
    dragging.current = false;
    setIsDragging(false);
    if (e.currentTarget.hasPointerCapture(e.pointerId)) {
      e.currentTarget.releasePointerCapture(e.pointerId);
    }
  };

  const onKeyDown = (e) => {
    if (e.key === "ArrowLeft") {
      e.preventDefault();
      setPosition((p) => Math.max(2, p - 4));
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      setPosition((p) => Math.min(98, p + 4));
    }
  };

  const allLoaded = loaded.before && loaded.after;
  const label = `${beforeLabel || s.beforeLabel} / ${afterLabel || s.afterLabel}`;
  const beforeWidth = containerWidth > 0 ? containerWidth : undefined;

  return (
    <div
      ref={containerRef}
      className={[
        "relative aspect-[16/10] overflow-hidden rounded-card bg-surface-muted shadow-card",
        "touch-none select-none",
        isDragging ? "cursor-grabbing" : "cursor-ew-resize",
        className,
      ].join(" ")}
      style={{ containerType: "inline-size" }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={endDrag}
      onPointerCancel={endDrag}
      onKeyDown={onKeyDown}
      role="slider"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(position)}
      tabIndex={0}
    >
      {!allLoaded ? <div className="absolute inset-0 skeleton rounded-card" aria-hidden="true" /> : null}

      <img
        src={afterUrl}
        alt={afterLabel || s.afterLabel}
        draggable={false}
        className={`pointer-events-none absolute inset-0 h-full w-full object-cover transition-opacity duration-500 ${loaded.after ? "opacity-100" : "opacity-0"}`}
        loading="lazy"
        decoding="async"
        onLoad={() => setLoaded((p) => ({ ...p, after: true }))}
      />

      <div
        className="pointer-events-none absolute inset-y-0 left-0 overflow-hidden"
        style={{ width: `${position}%` }}
      >
        <img
          src={beforeUrl}
          alt={beforeLabel || s.beforeLabel}
          draggable={false}
          className={`absolute left-0 top-0 h-full max-w-none object-cover transition-opacity duration-500 ${loaded.before ? "opacity-100" : "opacity-0"}`}
          style={{
            width: beforeWidth ?? "100cqw",
            minWidth: beforeWidth ?? "100cqw",
          }}
          loading="lazy"
          decoding="async"
          onLoad={() => setLoaded((p) => ({ ...p, before: true }))}
        />
      </div>

      <div
        className="pointer-events-none absolute inset-y-0 z-10"
        style={{ left: `${position}%` }}
        aria-hidden="true"
      >
        <div className="relative -ml-px h-full w-0.5 bg-white shadow-lg" />
        <div
          className={[
            "absolute left-1/2 top-1/2 flex h-11 w-11 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-2 border-white bg-white/95 shadow-elevated backdrop-blur",
            isDragging ? "cursor-grabbing" : "cursor-grab",
          ].join(" ")}
        >
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
