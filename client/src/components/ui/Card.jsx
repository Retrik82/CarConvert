export default function Card({
  children,
  className = "",
  elevated = false,
  selected = false,
  onClick,
  as: Tag = "div",
  padding = true,
}) {
  const interactive = Boolean(onClick);

  return (
    <Tag
      onClick={onClick}
      className={[
        "rounded-card border bg-surface transition-all duration-300 ease-standard",
        padding ? "p-5 sm:p-6" : "",
        elevated ? "shadow-elevated" : "shadow-card",
        selected ? "border-brand-500 ring-1 ring-brand-500/20" : "border-[var(--border)]/80",
        interactive
          ? "cursor-pointer hover:-translate-y-0.5 hover:shadow-elevated focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/30"
          : "",
        className,
      ].join(" ")}
    >
      {children}
    </Tag>
  );
}
