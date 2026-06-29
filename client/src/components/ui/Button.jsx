import { useState } from "react";

export default function Button({
  children,
  variant = "primary",
  size = "md",
  className = "",
  disabled,
  loading = false,
  type = "button",
  icon,
  ...props
}) {
  const [pressed, setPressed] = useState(false);
  const isDisabled = disabled || loading;

  const base =
    "inline-flex items-center justify-center gap-2 rounded-btn font-semibold transition-all duration-200 ease-standard focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 disabled:cursor-not-allowed disabled:opacity-50 active:scale-[0.98]";

  const variants = {
    primary:
      "bg-gradient-primary text-white shadow-button hover:brightness-105 hover:shadow-glow disabled:shadow-none",
    secondary:
      "border border-[var(--border)] bg-surface-muted text-ink hover:bg-white hover:shadow-sm",
    ghost: "text-ink-secondary hover:bg-surface-muted hover:text-ink",
    danger: "border border-red-100 bg-red-50 text-red-600 hover:bg-red-100",
    glass: "glass-panel text-ink hover:shadow-glass",
  };

  const sizes = {
    sm: "min-h-10 px-4 py-2 text-sm",
    md: "min-h-12 px-5 py-2.5 text-sm",
    lg: "min-h-14 px-6 py-3.5 text-base",
  };

  return (
    <button
      type={type}
      disabled={isDisabled}
      className={`${base} ${variants[variant]} ${sizes[size]} ${pressed && !isDisabled ? "scale-[0.98]" : ""} ${className}`}
      onPointerDown={() => !isDisabled && setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      {...props}
    >
      {loading ? (
        <span className="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
      ) : (
        <>
          {icon ? <span className="text-lg leading-none">{icon}</span> : null}
          {children}
        </>
      )}
    </button>
  );
}
