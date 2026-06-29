import { useEffect } from "react";
import Button from "./Button";

export default function Modal({ open, title, children, onClose, footer, wide = false }) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => {
      if (e.key === "Escape") onClose?.();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        type="button"
        aria-label="Close"
        className="absolute inset-0 bg-ink/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div
        className={[
          "relative z-10 w-full rounded-card border border-[var(--border)] bg-surface p-6 shadow-elevated animate-fade-up",
          wide ? "max-w-2xl max-h-[90vh] overflow-y-auto" : "max-w-md",
        ].join(" ")}
      >
        {title ? <h2 className="mb-4 text-lg font-semibold text-ink">{title}</h2> : null}
        <div>{children}</div>
        {footer ? <div className="mt-6 flex justify-end gap-3">{footer}</div> : null}
      </div>
    </div>
  );
}

export function ConfirmModal({ open, title, body, confirmLabel, cancelLabel, onConfirm, onClose, danger }) {
  return (
    <Modal
      open={open}
      title={title}
      onClose={onClose}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            {cancelLabel}
          </Button>
          <Button variant={danger ? "danger" : "primary"} onClick={onConfirm}>
            {confirmLabel}
          </Button>
        </>
      }
    >
      <p className="text-sm leading-relaxed text-ink-secondary">{body}</p>
    </Modal>
  );
}
