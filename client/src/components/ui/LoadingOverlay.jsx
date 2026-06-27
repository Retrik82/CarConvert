export default function LoadingOverlay({ active, progress = 0, label }) {
  if (!active) return null;

  return (
    <div className="absolute inset-0 z-20 flex flex-col items-center justify-center rounded-3xl bg-white/80 backdrop-blur-md">
      <div className="w-full max-w-xs px-6 text-center">
        <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-[3px] border-brand-200 border-t-brand-600" />
        {label ? <p className="mb-3 text-sm font-medium text-slate-700">{label}</p> : null}
        <div className="h-2 overflow-hidden rounded-full bg-slate-100">
          <div
            className="h-full rounded-full bg-gradient-to-r from-brand-600 to-violet-600 transition-all duration-500"
            style={{ width: `${Math.max(8, progress)}%` }}
          />
        </div>
        <p className="mt-2 text-xs text-slate-500">{Math.round(progress)}%</p>
      </div>
    </div>
  );
}
