export default function LoadingOverlay({ active, progress }) {
  if (!active) return null;

  return (
    <div className="absolute inset-0 z-40 flex items-center justify-center rounded-3xl bg-slate-950/55 backdrop-blur-sm">
      <div className="w-[80%] max-w-md rounded-2xl border border-sky-300/30 bg-slate-900/70 p-5">
        <p className="mb-3 text-sm text-slate-200">Generating photorealistic background...</p>
        <div className="h-2 overflow-hidden rounded-full bg-slate-700">
          <div
            className="h-full rounded-full bg-gradient-to-r from-cyan-400 to-teal-300 transition-all duration-300"
            style={{ width: `${Math.max(progress, 8)}%` }}
          />
        </div>
        <p className="mt-2 text-right text-xs text-slate-300">{Math.round(progress)}%</p>
      </div>
    </div>
  );
}
