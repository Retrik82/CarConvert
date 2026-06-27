import { Link } from "react-router-dom";
import { useStrings } from "../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher } from "../components/layout/AppChrome";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

export default function OnboardingPage() {
  const s = useStrings();

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-2xl flex-col px-4 py-6 sm:px-6">
      <div className="mb-6 flex items-center justify-between">
        <AppLogo />
        <LanguageSwitcher />
      </div>

      <div className="mb-8 overflow-hidden rounded-3xl bg-gradient-to-br from-brand-600/10 via-violet-500/5 to-transparent p-1">
        <BeforeAfterSlider
          beforeUrl=""
          afterUrl=""
          className="shadow-xl"
        />
      </div>

      <div className="text-center">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">
          {s.welcomeTitle.split("AutoCut")[0]}
          <span className="bg-gradient-to-r from-brand-600 to-violet-600 bg-clip-text text-transparent">
            AutoCut
          </span>
        </h1>
        <p className="mt-3 text-base text-slate-500">{s.welcomeSubtitle}</p>
        <p className="mt-1 text-sm text-slate-400">{s.appTagline}</p>
      </div>

      <div className="mt-10 space-y-3">
        <Link to="/login">
          <Button className="w-full" size="lg">
            {s.login}
          </Button>
        </Link>
        <Link to="/register">
          <Button variant="secondary" className="w-full" size="lg">
            {s.createAccount}
          </Button>
        </Link>
        <Link to="/download">
          <Button variant="ghost" className="w-full" size="lg">
            📲 {s.getTheApp}
          </Button>
        </Link>
      </div>

      <Card className="mt-8" elevated>
        <ul className="space-y-3 text-sm text-slate-600">
          <li className="flex gap-3">
            <span className="text-brand-600">✓</span>
            AI background replacement for car photos
          </li>
          <li className="flex gap-3">
            <span className="text-brand-600">✓</span>
            Studio presets & custom backgrounds
          </li>
          <li className="flex gap-3">
            <span className="text-brand-600">✓</span>
            Save renders to your garage
          </li>
        </ul>
      </Card>
    </div>
  );
}
