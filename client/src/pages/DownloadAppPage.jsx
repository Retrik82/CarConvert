import { Link } from "react-router-dom";
import { QRCodeSVG } from "qrcode.react";
import { QrCode } from "lucide-react";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { usePlatform } from "../hooks/usePlatform";
import { APP_VERSION } from "../theme/tokens";
import PublicShell from "../components/layout/PublicShell";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Reveal from "../components/ui/Reveal";
import { IconCheck, IconShield } from "../components/ui/Icons";

const ANDROID_APK_URL = import.meta.env.VITE_ANDROID_APK_URL || "/downloads/autocut.apk";
const GOOGLE_PLAY_URL = import.meta.env.VITE_GOOGLE_PLAY_URL || "";
const IOS_URL = import.meta.env.VITE_IOS_APP_STORE_URL || "";

function resolveApkUrl() {
  if (typeof window === "undefined") return ANDROID_APK_URL;
  return `${window.location.origin}${ANDROID_APK_URL.startsWith("/") ? ANDROID_APK_URL : `/${ANDROID_APK_URL}`}`;
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

function StoreQrBlock({ url, storeLabel, scanHint, comingSoonLabel }) {
  const hasUrl = Boolean(url);

  return (
    <div className="flex flex-col items-center rounded-input border border-dashed border-[var(--border)] bg-surface-muted/50 px-4 py-5 text-center">
      <p className="text-sm font-semibold text-ink">{storeLabel}</p>
      <p className="mt-1 text-xs text-ink-tertiary">{scanHint}</p>

      <div className="mt-4 flex h-[132px] w-[132px] items-center justify-center rounded-input border border-[var(--border)]/80 bg-white p-2 shadow-sm">
        {hasUrl ? (
          <QRCodeSVG
            value={url}
            size={116}
            level="M"
            includeMargin={false}
            bgColor="#ffffff"
            fgColor="#0f172a"
          />
        ) : (
          <div className="flex flex-col items-center gap-2 text-ink-tertiary" aria-hidden="true">
            <QrCode className="h-12 w-12 opacity-40" strokeWidth={1.5} />
            <span className="text-[10px] font-medium uppercase tracking-wide opacity-60">{comingSoonLabel}</span>
          </div>
        )}
      </div>
    </div>
  );
}

function PlatformCard({ title, children }) {
  return (
    <Card elevated className="flex h-full flex-col">
      <h3 className="mb-5 text-lg font-semibold text-ink">{title}</h3>
      <div className="flex flex-1 flex-col gap-4">{children}</div>
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
          <span className="min-w-0 pt-0.5">{step}</span>
        </li>
      ))}
    </ol>
  );
}

export default function DownloadAppPage({ embedded = false }) {
  const s = useStrings();
  const { isLoggedIn } = useAuth();
  const platform = usePlatform();
  const hasAndroidApk = Boolean(ANDROID_APK_URL);
  const hasIos = Boolean(IOS_URL);
  const apkUrl = resolveApkUrl();
  const androidQrUrl = GOOGLE_PLAY_URL || "";
  const iosQrUrl = IOS_URL;

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
        <div className="relative mb-8 overflow-hidden rounded-card bg-gradient-primary p-5 text-white shadow-elevated sm:mb-10 sm:p-10">
          <div
            className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-white/10 blur-3xl"
            aria-hidden="true"
          />
          <div className="relative grid items-center gap-6 lg:grid-cols-[1fr_auto] lg:gap-10 xl:gap-12">
            <div className="min-w-0 max-w-2xl">
              <p className="text-sm font-semibold uppercase tracking-wider text-white/75">{s.appName}</p>
              <h1 className="mt-2 text-3xl font-bold sm:text-4xl">{s.downloadAppHero}</h1>
              <p className="mt-4 text-base leading-relaxed text-white/85">{s.downloadAppHeroBody}</p>

              <ul className="mt-6 space-y-2">
                {s.downloadAppFeatures.map((feature) => (
                  <li key={feature} className="flex items-center gap-2 text-sm text-white/90">
                    <IconCheck className="h-4 w-4 shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>

            <div className="mx-auto flex flex-col items-center gap-4 lg:mx-0">
              <div className="animate-float relative">
                <div className="h-[240px] w-[120px] overflow-hidden rounded-[2rem] border-4 border-white/25 bg-white/10 shadow-2xl backdrop-blur sm:h-[280px] sm:w-[140px]">
                  <img
                    src="/images/after-showroom.jpg"
                    alt=""
                    className="h-full w-full object-cover"
                    loading="lazy"
                    sizes="140px"
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

      <div className="grid gap-6 sm:grid-cols-2">
        <Reveal delay={100}>
          <PlatformCard title={s.downloadAndroid}>
            {hasAndroidApk ? (
              <Button
                className="w-full"
                size="lg"
                onClick={() => {
                  const link = document.createElement("a");
                  link.href = apkUrl;
                  link.download = "";
                  link.click();
                }}
              >
                {s.downloadApk}
              </Button>
            ) : (
              <div className="rounded-input border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
                {s.downloadApkUnavailable}
              </div>
            )}
            <StoreQrBlock
              url={androidQrUrl}
              storeLabel={s.downloadQrGooglePlay}
              scanHint={s.downloadQrScanHint}
              comingSoonLabel={s.downloadQrComingSoon}
            />
            <StepList steps={s.downloadAndroidSteps} />
          </PlatformCard>
        </Reveal>

        <Reveal delay={150}>
          <PlatformCard title={s.downloadIos}>
            {hasIos ? (
              <Button
                variant="secondary"
                className="w-full"
                size="lg"
                onClick={() => window.open(IOS_URL, "_blank", "noopener,noreferrer")}
              >
                {s.downloadAppStore}
              </Button>
            ) : (
              <div className="rounded-input border border-[var(--border)] bg-surface-muted px-4 py-3 text-sm text-ink-secondary">
                {s.downloadIosComingSoon}
              </div>
            )}
            <StoreQrBlock
              url={iosQrUrl}
              storeLabel={s.downloadQrAppStore}
              scanHint={s.downloadQrScanHint}
              comingSoonLabel={s.downloadQrComingSoon}
            />
            <StepList steps={s.downloadIosSteps} />
          </PlatformCard>
        </Reveal>
      </div>

      <div className="mt-8 grid gap-6 md:grid-cols-2">
        <Reveal delay={200}>
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

        <Reveal delay={250}>
          <Card className="border-emerald-200/80 bg-emerald-50/30">
            <div className="flex gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-input bg-emerald-100 text-emerald-700">
                <IconShield className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <h3 className="font-semibold text-ink">{s.downloadSecurityTitle}</h3>
                <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{s.downloadSecurityBody}</p>
              </div>
            </div>
          </Card>
        </Reveal>
      </div>

      <Reveal delay={300}>
        <Card className="mt-8">
          <h3 className="font-semibold text-ink">{s.downloadWebOrApp}</h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{s.downloadWebOrAppBody}</p>
          {!isLoggedIn ? (
            <div className="mt-4 flex flex-wrap gap-3">
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
        <div className="mb-6 sm:mb-8">
          <h1 className="text-3xl font-bold text-ink sm:text-4xl">{s.downloadAppTitle}</h1>
          <p className="mt-2 text-ink-secondary">{s.downloadAppSubtitle}</p>
        </div>
        {content}
      </div>
    );
  }

  return <PublicShell wide>{content}</PublicShell>;
}
