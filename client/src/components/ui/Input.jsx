export default function Input({ label, error, className = "", id, ...props }) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");
  return (
    <label className={`block ${className}`} htmlFor={inputId}>
      {label ? <span className="mb-2 block text-sm font-medium text-slate-700">{label}</span> : null}
      <input
        id={inputId}
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-2 focus:ring-brand-500/20"
        {...props}
      />
      {error ? <span className="mt-1.5 block text-xs text-red-500">{error}</span> : null}
    </label>
  );
}

export function Textarea({ label, error, className = "", id, rows = 4, ...props }) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");
  return (
    <label className={`block ${className}`} htmlFor={inputId}>
      {label ? <span className="mb-2 block text-sm font-medium text-slate-700">{label}</span> : null}
      <textarea
        id={inputId}
        rows={rows}
        className="w-full resize-none rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-2 focus:ring-brand-500/20"
        {...props}
      />
      {error ? <span className="mt-1.5 block text-xs text-red-500">{error}</span> : null}
    </label>
  );
}
