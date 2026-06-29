import { useId, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useSettings, useStrings } from "../../contexts/SettingsContext";
import Reveal from "../ui/Reveal";
import Button from "../ui/Button";
import { AppLogoMark } from "../ui/Icons";

export function LanguageSwitcher({ className = "" }) {
  const { lang, setLang, languages } = useSettings();

  return (
    <div
      className={`flex items-center gap-0.5 rounded-input border border-[var(--border)] bg-surface-muted p-1 ${className}`}
      role="group"
      aria-label="Language"
    >
      {languages.map((item) => (
        <button
          key={item.code}
          type="button"
          onClick={() => setLang(item.code)}
          className={[
            "rounded-chip px-2.5 py-1.5 text-xs font-semibold transition-all duration-200",
            lang === item.code
              ? "bg-gradient-primary text-white shadow-sm"
              : "text-ink-tertiary hover:text-ink",
          ].join(" ")}
          aria-pressed={lang === item.code}
        >
          {item.code.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

export function AppLogo({ size = "md", linkTo }) {
  const gradientId = useId();
  const sizes = {
    sm: { icon: "h-8 w-8", title: "text-lg", gap: "gap-2.5" },
    md: { icon: "h-10 w-10", title: "text-xl", gap: "gap-3" },
    lg: { icon: "h-12 w-12", title: "text-2xl", gap: "gap-3" },
  };
  const s = sizes[size] || sizes.md;

  const content = (
    <div className={`flex items-center ${s.gap}`}>
      <AppLogoMark className={`${s.icon} shrink-0`} gradientId={gradientId.replace(/:/g, "")} />
      <span className={`${s.title} font-bold tracking-tight text-ink`}>AutoCut</span>
    </div>
  );

  if (linkTo === false) return content;

  return (
    <Link to={linkTo || "/welcome"} className="inline-flex transition-opacity hover:opacity-90">
      {content}
    </Link>
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

export function PageHeader({ title, subtitle, action, eyebrow }) {
  return (
    <Reveal className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        {eyebrow ? (
          <p className="mb-2 text-sm font-semibold uppercase tracking-wider text-brand-600">{eyebrow}</p>
        ) : null}
        <h1 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl">{title}</h1>
        {subtitle ? <p className="mt-2 max-w-2xl text-base leading-relaxed text-ink-secondary">{subtitle}</p> : null}
      </div>
      {action}
    </Reveal>
  );
}

export function EmptyState({ icon, title, subtitle, action }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-card border border-dashed border-[var(--border)] bg-surface-muted/40 px-6 py-16 text-center">
      {icon ? (
        <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-input bg-brand-50 text-brand-600 [&_svg]:h-7 [&_svg]:w-7">
          {icon}
        </div>
      ) : null}
      <h3 className="text-lg font-semibold text-ink">{title}</h3>
      {subtitle ? <p className="mt-2 max-w-sm text-sm leading-relaxed text-ink-secondary">{subtitle}</p> : null}
      {action ? <div className="mt-6">{action}</div> : null}
    </div>
  );
}

export function Spinner({ className = "h-8 w-8", label }) {
  return (
    <div className="flex flex-col items-center gap-3" role="status" aria-live="polite">
      <div
        className={`animate-spin rounded-full border-[3px] border-brand-100 border-t-brand-600 ${className}`}
        aria-hidden="true"
      />
      {label ? <span className="text-sm text-ink-secondary">{label}</span> : null}
    </div>
  );
}

export function MarketingHeader() {
  const { isLoggedIn } = useAuth();
  const s = useStrings();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const navLinks = [
    { to: "/welcome#features", label: s.marketingNavFeatures },
    { to: "/welcome#how-it-works", label: s.marketingNavHowItWorks },
    { to: "/welcome#faq", label: s.marketingNavFaq },
    { to: "/download", label: s.marketingNavDownload },
  ];

  const isActive = (to) => {
    if (to === "/download") return location.pathname === "/download";
    return location.pathname === "/welcome" && location.hash === to.replace("/welcome", "");
  };

  return (
    <header className="sticky top-0 z-50 glass-header">
      <div className="section-container flex h-16 items-center justify-between gap-4 lg:h-[72px]">
        <AppLogo size="sm" />

        <nav className="hidden items-center gap-1 md:flex" aria-label="Main">
          {navLinks.map((link) => (
            <Link
              key={link.to}
              to={link.to}
              className={[
                "rounded-btn px-4 py-2 text-sm font-medium transition-colors",
                isActive(link.to) ? "text-brand-600" : "text-ink-secondary hover:text-ink",
              ].join(" ")}
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          <LanguageSwitcher />
          {isLoggedIn ? (
            <Link to="/app">
              <Button size="sm">{s.dashboard}</Button>
            </Link>
          ) : (
            <>
              <Link to="/login">
                <Button size="sm" variant="ghost">
                  {s.login}
                </Button>
              </Link>
              <Link to="/register">
                <Button size="sm">{s.getStarted}</Button>
              </Link>
            </>
          )}
        </div>

        <button
          type="button"
          className="flex h-10 w-10 items-center justify-center rounded-btn border border-[var(--border)] md:hidden"
          aria-expanded={mobileOpen}
          aria-label="Toggle menu"
          onClick={() => setMobileOpen((v) => !v)}
        >
          <span className="text-lg">{mobileOpen ? "✕" : "☰"}</span>
        </button>
      </div>

      {mobileOpen ? (
        <div className="border-t border-[var(--border)]/60 bg-white/95 px-6 py-4 backdrop-blur-xl md:hidden animate-slide-down">
          <nav className="flex flex-col gap-1" aria-label="Mobile">
            {navLinks.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className="rounded-btn px-4 py-3 text-sm font-medium text-ink-secondary hover:bg-surface-muted"
                onClick={() => setMobileOpen(false)}
              >
                {link.label}
              </Link>
            ))}
          </nav>
          <div className="mt-4 flex flex-col gap-2 border-t border-[var(--border)]/60 pt-4">
            <LanguageSwitcher className="w-fit" />
            {isLoggedIn ? (
              <Link to="/app" onClick={() => setMobileOpen(false)}>
                <Button className="w-full">{s.dashboard}</Button>
              </Link>
            ) : (
              <>
                <Link to="/login" onClick={() => setMobileOpen(false)}>
                  <Button variant="secondary" className="w-full">
                    {s.login}
                  </Button>
                </Link>
                <Link to="/register" onClick={() => setMobileOpen(false)}>
                  <Button className="w-full">{s.getStarted}</Button>
                </Link>
              </>
            )}
          </div>
        </div>
      ) : null}
    </header>
  );
}
