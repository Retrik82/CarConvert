export default function Card({ children, className = "", elevated = false, onClick, as: Tag = "div" }) {
  const interactive = Boolean(onClick);
  return (
    <Tag
      onClick={onClick}
      className={[
        "rounded-3xl border border-slate-200/80 bg-white p-5 sm:p-6",
        elevated ? "shadow-xl shadow-slate-200/60" : "shadow-sm shadow-slate-100",
        interactive ? "cursor-pointer transition hover:-translate-y-0.5 hover:shadow-lg hover:shadow-slate-200/70" : "",
        className,
      ].join(" ")}
    >
      {children}
    </Tag>
  );
}
