import { useSettings } from "../../contexts/SettingsContext";

export function LanguageSwitcher({ className = "" }) {
  const { lang, setLang, languages } = useSettings();

  return (
    <div className={`flex items-center gap-1 rounded-xl border border-slate-200 bg-white p-1 ${className}`}>
      {languages.map((item) => (
        <button
          key={item.code}
          type="button"
          onClick={() => setLang(item.code)}
          className={[
            "rounded-lg px-2.5 py-1 text-xs font-semibold transition",
            lang === item.code ? "bg-brand-600 text-white" : "text-slate-500 hover:text-slate-800",
          ].join(" ")}
        >
          {item.code.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

export function AppLogo({ size = "md" }) {
  const sizes = {
    sm: { icon: "h-8 w-8 text-sm", title: "text-lg" },
    md: { icon: "h-10 w-10 text-base", title: "text-xl" },
    lg: { icon: "h-12 w-12 text-lg", title: "text-2xl" },
  };
  const s = sizes[size] || sizes.md;

  return (
    <div className="flex items-center gap-3">
      <div
        className={`flex ${s.icon} items-center justify-center rounded-2xl bg-gradient-to-br from-brand-600 to-violet-600 font-bold text-white shadow-lg shadow-brand-500/30`}
      >
        A
      </div>
      <span className={`${s.title} font-bold tracking-tight text-slate-900`}>AutoCut</span>
    </div>
  );
}

export function TopBar({ trailing }) {
  return (
    <header className="flex items-center justify-between gap-4 py-4">
      <AppLogo />
      <div className="flex items-center gap-3">
        <LanguageSwitcher />
        {trailing}
      </div>
    </header>
  );
}

export function PageHeader({ title, subtitle, action }) {
  return (
    <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">{title}</h1>
        {subtitle ? <p className="mt-2 text-base text-slate-500">{subtitle}</p> : null}
      </div>
      {action}
    </div>
  );
}

export function EmptyState({ icon, title, subtitle, action }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-3xl border border-dashed border-slate-200 bg-slate-50/50 px-6 py-16 text-center">
      {icon ? <div className="mb-4 text-4xl opacity-60">{icon}</div> : null}
      <h3 className="text-lg font-semibold text-slate-800">{title}</h3>
      {subtitle ? <p className="mt-2 max-w-sm text-sm text-slate-500">{subtitle}</p> : null}
      {action ? <div className="mt-6">{action}</div> : null}
    </div>
  );
}

export function Spinner({ className = "h-8 w-8" }) {
  return (
    <div
      className={`animate-spin rounded-full border-[3px] border-brand-200 border-t-brand-600 ${className}`}
    />
  );
}
