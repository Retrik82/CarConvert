import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";

function ActionCard({ icon, title, subtitle, to, highlighted }) {
  return (
    <Link to={to}>
      <Card elevated={highlighted} className="group">
        <div className="flex items-center gap-4">
          <div
            className={[
              "flex h-13 w-13 shrink-0 items-center justify-center rounded-2xl text-2xl",
              highlighted
                ? "bg-gradient-to-br from-brand-600 to-violet-600 text-white shadow-lg shadow-brand-500/30"
                : "bg-brand-50 text-brand-600",
            ].join(" ")}
          >
            {icon}
          </div>
          <div className="min-w-0 flex-1">
            <h3 className="font-semibold text-slate-900">{title}</h3>
            <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p>
          </div>
          <span className="text-slate-300 transition group-hover:translate-x-0.5 group-hover:text-slate-400">
            →
          </span>
        </div>
      </Card>
    </Link>
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

      <BeforeAfterSlider className="mb-8 shadow-xl shadow-slate-200/60" />

      {selected ? (
        <Card className="mb-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-600 to-violet-600 text-white">
              ✓
            </div>
            <div>
              <p className="text-xs text-slate-500">{s.backgroundSelected}</p>
              <p className="font-semibold text-slate-900">{selected.displayName}</p>
            </div>
          </div>
        </Card>
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
        />
        <ActionCard
          icon="📷"
          title={s.takePhoto}
          subtitle={s.startCapture}
          to="/app/capture?mode=camera"
          highlighted
        />
        <ActionCard
          icon="🖼️"
          title={s.fromGallery}
          subtitle={s.startCapture}
          to="/app/capture?mode=gallery"
        />
      </div>
    </div>
  );
}
