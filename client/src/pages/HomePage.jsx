import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";
import Reveal from "../components/ui/Reveal";

function ActionCard({ icon, title, subtitle, to, highlighted, delay = 0 }) {
  return (
    <Reveal delay={delay}>
      <Link to={to} className="block">
        <Card elevated={highlighted} className="group">
          <div className="flex items-center gap-4">
            <div
              className={[
                "flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-input text-2xl transition",
                highlighted
                  ? "bg-gradient-primary text-white shadow-button"
                  : "bg-brand-50 text-brand-600",
              ].join(" ")}
            >
              {icon}
            </div>
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
        <BeforeAfterSlider className="mb-8 shadow-elevated" />
      </Reveal>

      {selected ? (
        <Reveal delay={50}>
          <Card className="mb-4">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-chip bg-gradient-primary text-white shadow-button">
                ✓
              </div>
              <div>
                <p className="text-xs text-ink-secondary">{s.backgroundSelected}</p>
                <p className="font-semibold text-ink">{selected.displayName}</p>
              </div>
            </div>
          </Card>
        </Reveal>
      ) : null}

      <div className="space-y-3">
        <ActionCard
          icon="🎨"
          title={selected ? s.changeBackground : s.chooseBackground}
          subtitle={s.backgroundsIntro.split(".")[0]}
          to="/app/backgrounds"
          highlighted={!selected}
        />
        <ActionCard
          icon="⚙️"
          title={s.configureStudio}
          subtitle={s.configTitle}
          to="/app/configurator"
          delay={50}
        />
        <ActionCard
          icon="📷"
          title={s.takePhoto}
          subtitle={s.startCapture}
          to="/app/capture?mode=camera"
          highlighted
          delay={100}
        />
        <ActionCard
          icon="🖼️"
          title={s.fromGallery}
          subtitle={s.startCapture}
          to="/app/capture?mode=gallery"
          delay={150}
        />
      </div>
    </div>
  );
}
