export default function Button({
  children,
  variant = "primary",
  size = "md",
  className = "",
  disabled,
  type = "button",
  ...props
}) {
  const base =
    "inline-flex items-center justify-center gap-2 rounded-2xl font-semibold transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 disabled:cursor-not-allowed disabled:opacity-50";

  const variants = {
    primary:
      "bg-gradient-to-r from-brand-600 to-violet-600 text-white shadow-lg shadow-brand-500/25 hover:brightness-105 hover:shadow-brand-500/35",
    secondary:
      "border border-slate-200 bg-white text-slate-800 hover:bg-slate-50 shadow-sm",
    ghost: "text-slate-600 hover:bg-slate-100",
    danger: "bg-red-50 text-red-600 border border-red-100 hover:bg-red-100",
  };

  const sizes = {
    sm: "px-4 py-2 text-sm",
    md: "px-5 py-2.5 text-sm",
    lg: "px-6 py-3 text-base",
  };

  return (
    <button
      type={type}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}
