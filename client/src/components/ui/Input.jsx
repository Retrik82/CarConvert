export default function Input({ label, error, className = "", id, ...props }) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <label className={`block ${className}`} htmlFor={inputId}>
      {label ? (
        <span className="mb-2 block text-sm font-medium text-ink-secondary">{label}</span>
      ) : null}
      <input
        id={inputId}
        className={[
          "w-full rounded-input border border-[var(--border)] bg-surface-muted px-[18px] py-[18px] text-base text-ink outline-none transition placeholder:text-ink-tertiary",
          "focus:border-brand-600 focus:bg-white focus:ring-2 focus:ring-brand-500/15",
          error ? "border-red-400 focus:border-red-500 focus:ring-red-500/15" : "",
        ].join(" ")}
        aria-invalid={error ? "true" : undefined}
        {...props}
      />
      {error ? (
        <span className="mt-1.5 block text-sm text-red-600" role="alert">
          {error}
        </span>
      ) : null}
    </label>
  );
}

export function Textarea({ label, error, className = "", id, rows = 4, ...props }) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <label className={`block ${className}`} htmlFor={inputId}>
      {label ? (
        <span className="mb-2 block text-sm font-medium text-ink-secondary">{label}</span>
      ) : null}
      <textarea
        id={inputId}
        rows={rows}
        className={[
          "w-full resize-none rounded-input border border-[var(--border)] bg-surface-muted px-[18px] py-[18px] text-base text-ink outline-none transition placeholder:text-ink-tertiary",
          "focus:border-brand-600 focus:bg-white focus:ring-2 focus:ring-brand-500/15",
          error ? "border-red-400" : "",
        ].join(" ")}
        {...props}
      />
      {error ? <span className="mt-1.5 block text-sm text-red-600">{error}</span> : null}
    </label>
  );
}
