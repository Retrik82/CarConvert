import { useEffect } from "react";

export default function Toast({ message, onClose }) {
  useEffect(() => {
    if (!message) return;
    const timer = setTimeout(onClose, 5000);
    return () => clearTimeout(timer);
  }, [message, onClose]);

  if (!message) return null;

  return (
    <div className="fixed bottom-6 left-1/2 z-[60] w-[min(92vw,28rem)] -translate-x-1/2 animate-fade-up" role="alert">
      <div className="flex items-start gap-3 rounded-card border border-red-200 bg-surface px-4 py-3 shadow-elevated">
        <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-xs text-red-600">
          !
        </span>
        <p className="flex-1 text-sm text-ink">{message}</p>
        <button
          type="button"
          onClick={onClose}
          className="text-ink-tertiary transition hover:text-ink"
          aria-label="Dismiss"
        >
          ×
        </button>
      </div>
    </div>
  );
}
