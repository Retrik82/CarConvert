import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { PageHeader } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";

const ANDROID_URL = import.meta.env.VITE_ANDROID_APK_URL || "";
const IOS_URL = import.meta.env.VITE_IOS_APP_STORE_URL || "";

function PlatformCard({ icon, title, subtitle, children, accent }) {
  return (
    <Card elevated className="flex h-full flex-col">
      <div className="mb-4 flex items-center gap-4">
        <div
          className={[
            "flex h-14 w-14 items-center justify-center rounded-2xl text-2xl text-white shadow-lg",
            accent,
          ].join(" ")}
        >
          {icon}
        </div>
        <div>
          <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
          <p className="text-sm text-slate-500">{subtitle}</p>
        </div>
      </div>
      <div className="mt-auto space-y-4">{children}</div>
    </Card>
  );
}

function StepList({ steps }) {
  return (
    <ol className="space-y-2">
      {steps.map((step, i) => (
        <li key={step} className="flex gap-3 text-sm text-slate-600">
          <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand-50 text-xs font-bold text-brand-700">
            {i + 1}
          </span>
          <span className="pt-0.5">{step}</span>
        </li>
      ))}
    </ol>
  );
}

export default function DownloadAppPage() {
  const s = useStrings();
  const { isLoggedIn } = useAuth();
  const hasAndroid = Boolean(ANDROID_URL);
  const hasIos = Boolean(IOS_URL);

  return (
    <div>
      <PageHeader title={s.downloadAppTitle} subtitle={s.downloadAppSubtitle} />

      <div className="mb-8 overflow-hidden rounded-3xl bg-gradient-to-br from-brand-600 to-violet-600 p-6 text-white shadow-xl shadow-brand-500/25 sm:p-8">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div className="max-w-lg">
            <p className="text-sm font-semibold uppercase tracking-wide text-white/80">{s.appName}</p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{s.downloadAppHero}</h2>
            <p className="mt-3 text-sm leading-relaxed text-white/85">{s.downloadAppHeroBody}</p>
          </div>
          <div className="mx-auto flex h-48 w-28 shrink-0 items-center justify-center rounded-[2rem] border-4 border-white/20 bg-white/10 shadow-2xl backdrop-blur sm:mx-0">
            <span className="text-5xl">📱</span>
          </div>
        </div>
      </div>

      <ul className="mb-8 grid gap-3 sm:grid-cols-3">
        {s.downloadAppFeatures.map((feature) => (
          <li
            key={feature}
            className="flex items-start gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 shadow-sm"
          >
            <span className="text-brand-600">✓</span>
            {feature}
          </li>
        ))}
      </ul>

      <div className="grid gap-6 lg:grid-cols-2">
        <PlatformCard
          icon="🤖"
          title={s.downloadAndroid}
          subtitle={s.downloadAndroidSubtitle}
          accent="bg-gradient-to-br from-emerald-500 to-green-600 shadow-emerald-500/30"
        >
          {hasAndroid ? (
            <a href={ANDROID_URL} download className="block">
              <Button className="w-full" size="lg">
                {s.downloadApk}
              </Button>
            </a>
          ) : (
            <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
              {s.downloadApkUnavailable}
            </div>
          )}
          <StepList steps={s.downloadAndroidSteps} />
        </PlatformCard>

        <PlatformCard
          icon="🍎"
          title={s.downloadIos}
          subtitle={s.downloadIosSubtitle}
          accent="bg-gradient-to-br from-slate-700 to-slate-900 shadow-slate-500/30"
        >
          {hasIos ? (
            <a href={IOS_URL} target="_blank" rel="noopener noreferrer" className="block">
              <Button variant="secondary" className="w-full" size="lg">
                {s.downloadAppStore}
              </Button>
            </a>
          ) : (
            <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
              {s.downloadIosComingSoon}
            </div>
          )}
          <StepList steps={s.downloadIosSteps} />
        </PlatformCard>
      </div>

      <Card className="mt-8">
        <h3 className="font-semibold text-slate-900">{s.downloadWebOrApp}</h3>
        <p className="mt-2 text-sm leading-relaxed text-slate-600">{s.downloadWebOrAppBody}</p>
        {!isLoggedIn ? (
          <div className="mt-4 flex flex-wrap gap-3">
            <Link to="/login">
              <Button>{s.login}</Button>
            </Link>
            <Link to="/welcome">
              <Button variant="secondary">{s.goHome}</Button>
            </Link>
          </div>
        ) : null}
      </Card>
    </div>
  );
}
