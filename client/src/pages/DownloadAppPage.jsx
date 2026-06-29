import { useMemo } from "react";
import { Link } from "react-router-dom";
import { QRCodeSVG } from "qrcode.react";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { usePlatform } from "../hooks/usePlatform";
import { APP_VERSION } from "../theme/tokens";
import PublicShell from "../components/layout/PublicShell";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Reveal from "../components/ui/Reveal";

const ANDROID_URL = import.meta.env.VITE_ANDROID_APK_URL || "/downloads/autocut.apk";
const IOS_URL = import.meta.env.VITE_IOS_APP_STORE_URL || "";

function resolveDownloadUrl() {
  if (typeof window === "undefined") return ANDROID_URL;
  return `${window.location.origin}${ANDROID_URL.startsWith("/") ? ANDROID_URL : `/${ANDROID_URL}`}`;
}

function PlatformBadge({ platform, s }) {
  const labels = {
    ios: s.downloadPlatformIos,
    android: s.downloadPlatformAndroid,
    desktop: s.downloadPlatformDesktop,
  };

  return (
    <div className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-brand-50 px-4 py-2 text-sm font-medium text-brand-700">
      <span className="h-2 w-2 animate-pulse-soft rounded-full bg-brand-600" aria-hidden="true" />
      {labels[platform] || labels.desktop}
    </div>
  );
}

function PlatformCard({ icon, title, subtitle, children, accent, recommended }) {
  return (
    <Card elevated className={`relative flex h-full flex-col ${recommended ? "ring-2 ring-brand-500/30" : ""}`}>
      {recommended ? (
        <span className="absolute -top-3 left-6 rounded-full bg-gradient-primary px-3 py-1 text-xs font-semibold text-white shadow-button">
          ★ Recommended
        </span>
      ) : null}
      <div className="mb-4 flex items-center gap-4">
        <div
          className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-input text-2xl text-white shadow-lg ${accent}`}
        >
          {icon}
        </div>
        <div>
          <h3 className="text-lg font-semibold text-ink">{title}</h3>
          <p className="text-sm text-ink-secondary">{subtitle}</p>
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
        <li key={step} className="flex gap-3 text-sm text-ink-secondary">
          <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand-50 text-xs font-bold text-brand-700">
            {i + 1}
          </span>
          <span className="pt-0.5">{step}</span>
        </li>
      ))}
    </ol>
  );
}

export default function DownloadAppPage({ embedded = false }) {
  const s = useStrings();
  const { isLoggedIn } = useAuth();
  const platform = usePlatform();
  const hasAndroid = Boolean(ANDROID_URL);
  const hasIos = Boolean(IOS_URL);
  const downloadPageUrl = useMemo(
    () => (typeof window !== "undefined" ? `${window.location.origin}/download` : "/download"),
    [],
  );
  const apkUrl = resolveDownloadUrl();

  const content = (
    <div className="page-enter">
      <Reveal>
        <div className="mb-6 flex flex-wrap items-center gap-3">
          <PlatformBadge platform={platform} s={s} />
          <span className="text-sm text-ink-tertiary">
            {s.downloadVersion}: <strong className="text-ink">v{APP_VERSION}</strong>
          </span>
        </div>
      </Reveal>

      <Reveal delay={50}>
        <div className="relative mb-10 overflow-hidden rounded-card bg-gradient-primary p-6 text-white shadow-elevated sm:p-10">
          <div
            className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-white/10 blur-3xl"
            aria-hidden="true"
          />
          <div className="relative grid items-center gap-8 lg:grid-cols-[1fr_auto]">
            <div className="max-w-xl">
              <p className="text-sm font-semibold uppercase tracking-wider text-white/75">{s.appName}</p>
              <h1 className="mt-2 text-3xl font-bold sm:text-4xl">{s.downloadAppHero}</h1>
              <p className="mt-4 text-base leading-relaxed text-white/85">{s.downloadAppHeroBody}</p>

              <ul className="mt-6 space-y-2">
                {s.downloadAppFeatures.map((feature) => (
                  <li key={feature} className="flex items-center gap-2 text-sm text-white/90">
                    <span aria-hidden="true">✓</span>
                    {feature}
                  </li>
                ))}
              </ul>
            </div>

            <div className="mx-auto flex flex-col items-center gap-4 lg:mx-0">
              <div className="animate-float relative">
                <div className="h-[280px] w-[140px] overflow-hidden rounded-[2rem] border-4 border-white/25 bg-white/10 shadow-2xl backdrop-blur">
                  <img
                    src="/images/after-showroom.jpg"
                    alt=""
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                </div>
                <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 rounded-full bg-white/20 px-3 py-1 text-xs backdrop-blur">
                  AutoCut
                </div>
              </div>
            </div>
          </div>
        </div>
      </Reveal>

      <div className="grid gap-8 lg:grid-cols-[1fr_280px]">
        <div className="grid gap-6 lg:grid-cols-2">
          <Reveal delay={100}>
            <PlatformCard
              icon="🤖"
              title={s.downloadAndroid}
              subtitle={s.downloadAndroidSubtitle}
              accent="bg-gradient-to-br from-emerald-500 to-green-600"
              recommended={platform === "android" || (platform === "desktop" && hasAndroid)}
            >
              {hasAndroid ? (
                <a href={apkUrl} download className="block">
                  <Button className="w-full" size="lg">
                    {s.downloadApk}
                  </Button>
                </a>
              ) : (
                <div className="rounded-input border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
                  {s.downloadApkUnavailable}
                </div>
              )}
              <StepList steps={s.downloadAndroidSteps} />
            </PlatformCard>
          </Reveal>

          <Reveal delay={150}>
            <PlatformCard
              icon="🍎"
              title={s.downloadIos}
              subtitle={s.downloadIosSubtitle}
              accent="bg-gradient-to-br from-slate-700 to-slate-900"
              recommended={platform === "ios"}
            >
              {hasIos ? (
                <a href={IOS_URL} target="_blank" rel="noopener noreferrer" className="block">
                  <Button variant="secondary" className="w-full" size="lg">
                    {s.downloadAppStore}
                  </Button>
                </a>
              ) : (
                <div className="rounded-input border border-[var(--border)] bg-surface-muted px-4 py-3 text-sm text-ink-secondary">
                  {s.downloadIosComingSoon}
                </div>
              )}
              <StepList steps={s.downloadIosSteps} />
            </PlatformCard>
          </Reveal>
        </div>

        <Reveal delay={200}>
          <Card elevated className="flex h-full flex-col items-center text-center">
            <h3 className="font-semibold text-ink">{s.downloadQrTitle}</h3>
            <p className="mt-2 text-sm text-ink-secondary">{s.downloadQrBody}</p>
            <div className="mt-6 rounded-card border border-[var(--border)] bg-white p-4 shadow-card">
              <QRCodeSVG
                value={downloadPageUrl}
                size={180}
                level="M"
                includeMargin
                bgColor="#ffffff"
                fgColor="#0f172a"
              />
            </div>
            <p className="mt-4 break-all text-xs text-ink-tertiary">{downloadPageUrl}</p>
          </Card>
        </Reveal>
      </div>

      <div className="mt-8 grid gap-6 md:grid-cols-2">
        <Reveal delay={250}>
          <Card>
            <h3 className="font-semibold text-ink">{s.downloadWhatsNew}</h3>
            <ul className="mt-4 space-y-3">
              {s.downloadWhatsNewItems.map((item) => (
                <li key={item} className="flex gap-2 text-sm text-ink-secondary">
                  <span className="text-brand-600" aria-hidden="true">
                    •
                  </span>
                  {item}
                </li>
              ))}
            </ul>
          </Card>
        </Reveal>

        <Reveal delay={300}>
          <Card className="border-emerald-200/80 bg-emerald-50/30">
            <div className="flex gap-3">
              <span className="text-2xl" aria-hidden="true">
                🛡️
              </span>
              <div>
                <h3 className="font-semibold text-ink">{s.downloadSecurityTitle}</h3>
                <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{s.downloadSecurityBody}</p>
              </div>
            </div>
          </Card>
        </Reveal>
      </div>

      <Reveal delay={350}>
        <Card className="mt-8">
          <h3 className="font-semibold text-ink">{s.downloadWebOrApp}</h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{s.downloadWebOrAppBody}</p>
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
      </Reveal>
    </div>
  );

  if (embedded) {
    return (
      <div>
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-ink">{s.downloadAppTitle}</h1>
          <p className="mt-2 text-ink-secondary">{s.downloadAppSubtitle}</p>
        </div>
        {content}
      </div>
    );
  }

  return <PublicShell wide>{content}</PublicShell>;
}
