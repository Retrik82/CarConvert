export default function Toast({ message, onClose }) {
  if (!message) return null;

  return (
    <div className="fixed bottom-5 right-5 z-50 max-w-sm rounded-xl border border-rose-400/40 bg-rose-500/20 px-4 py-3 text-sm text-rose-100 shadow-glow backdrop-blur-md">
      <div className="flex items-start justify-between gap-3">
        <p>{message}</p>
        <button
          className="rounded-md bg-rose-950/40 px-2 py-0.5 text-xs hover:bg-rose-900/50"
          onClick={onClose}
        >
          Close
        </button>
      </div>
    </div>
  );
}
