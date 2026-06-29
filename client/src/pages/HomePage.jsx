import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";
import Reveal from "../components/ui/Reveal";
import {
  IconCamera,
  IconCheck,
  IconGallery,
  IconPalette,
  IconSettings,
  IconSlot,
} from "../components/ui/Icons";

function ActionCard({ icon, title, subtitle, to, highlighted, delay = 0 }) {
  return (
    <Reveal delay={delay}>
      <Link to={to} className="block">
        <Card elevated={highlighted} className="group">
          <div className="flex items-center gap-4">
            <IconSlot highlighted={highlighted} className="h-[52px] w-[52px] [&_svg]:h-6 [&_svg]:w-6">
              {icon}
            </IconSlot>
            <div className="min-w-0 flex-1">
              <h3 className="font-semibold text-ink">{title}</h3>
              <p className="mt-0.5 text-sm text-ink-secondary">{subtitle}</p>
            </div>
            <svg
              className="h-4 w-4 shrink-0 text-ink-tertiary transition group-hover:translate-x-0.5 group-hover:text-brand-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </Card>
      </Link>
    </Reveal>
  );
}

export default function HomePage() {
  const s = useStrings();
  const { user } = useAuth();
  const { selected } = useBackground();
  const name = user?.display_name || "there";

  return (
    <div>
      <PageHeader title={s.greeting(name)} subtitle={s.dashboardSubtitle} />

      <Reveal>
        <BeforeAfterSlider className="mb-6 shadow-elevated sm:mb-8" />
      </Reveal>

      {selected ? (
        <Reveal delay={50}>
          <Card className="mb-4">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-chip bg-gradient-primary text-white shadow-button">
                <IconCheck className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <p className="text-xs text-ink-secondary">{s.backgroundSelected}</p>
                <p className="truncate font-semibold text-ink">{selected.displayName}</p>
              </div>
            </div>
          </Card>
        </Reveal>
      ) : null}

      <div className="space-y-3">
        <ActionCard
          icon={<IconPalette />}
          title={selected ? s.changeBackground : s.chooseBackground}
          subtitle={s.backgroundsIntro.split(".")[0]}
          to="/app/backgrounds"
          highlighted={!selected}
        />
        <ActionCard icon={<IconSettings />} title={s.configureStudio} subtitle={s.configTitle} to="/app/configurator" delay={50} />
        <ActionCard icon={<IconCamera />} title={s.takePhoto} subtitle={s.startCapture} to="/app/capture?mode=camera" highlighted delay={100} />
        <ActionCard icon={<IconGallery />} title={s.fromGallery} subtitle={s.startCapture} to="/app/capture?mode=gallery" delay={150} />
      </div>
    </div>
  );
}
