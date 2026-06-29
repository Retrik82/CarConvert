import { Link } from "react-router-dom";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo } from "./AppChrome";
import Reveal from "../ui/Reveal";

export default function MarketingFooter() {
  const s = useStrings();
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-[var(--border)]/60 bg-surface-elevated">
      <div className="section-container py-16">
        <Reveal className="grid gap-12 md:grid-cols-2 lg:grid-cols-4">
          <div className="lg:col-span-2">
            <AppLogo size="md" linkTo="/welcome" />
            <p className="mt-4 max-w-sm text-sm leading-relaxed text-ink-secondary">{s.footerTagline}</p>
          </div>

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-ink">{s.footerProduct}</h3>
            <ul className="mt-4 space-y-3 text-sm">
              <li>
                <Link to="/welcome#features" className="text-ink-secondary transition hover:text-brand-600">
                  {s.footerFeatures}
                </Link>
              </li>
              <li>
                <Link to="/download" className="text-ink-secondary transition hover:text-brand-600">
                  {s.getTheApp}
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-ink">{s.footerLegal}</h3>
            <ul className="mt-4 space-y-3 text-sm text-ink-secondary">
              <li>{s.footerOfficial}</li>
              <li>© {year} {s.appName}</li>
            </ul>
          </div>
        </Reveal>
      </div>
    </footer>
  );
}
