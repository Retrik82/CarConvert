import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useStrings } from "../contexts/SettingsContext";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { PageHeader } from "../components/layout/AppChrome";

const STEPS = ["color", "wheels", "interior", "studio", "summary"];

const OPTIONS = {
  color: [
    { id: "black", label: "Obsidian Black", swatch: "#111827" },
    { id: "white", label: "Alpine White", swatch: "#F8FAFC" },
    { id: "blue", label: "Marina Bay Blue", swatch: "#2563EB" },
    { id: "red", label: "Toronto Red", swatch: "#DC2626" },
  ],
  wheels: [
    { id: "sport", label: "Sport Alloy" },
    { id: "multi", label: "Multi-spoke" },
    { id: "forged", label: "Forged Performance" },
  ],
  interior: [
    { id: "black", label: "Black Vernasca" },
    { id: "cognac", label: "Cognac Leather" },
    { id: "white", label: "Ivory Stitch" },
  ],
  studio: [
    { id: "showroom", label: "Gray Showroom" },
    { id: "workshop", label: "Auto Workshop" },
    { id: "outdoor", label: "Golden Hour" },
  ],
};

function OptionGrid({ options, value, onChange, colorKey }) {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-2">
      {options.map((opt) => (
        <button
          key={opt.id}
          type="button"
          onClick={() => onChange(opt.id)}
          className={[
            "rounded-2xl border p-4 text-left transition",
            value === opt.id
              ? "border-brand-500 bg-brand-50 ring-2 ring-brand-200"
              : "border-[var(--border)] hover:border-slate-300",
          ].join(" ")}
        >
          {colorKey && opt.swatch ? (
            <span
              className="mb-2 inline-block h-8 w-8 rounded-full border border-[var(--border)]"
              style={{ background: opt.swatch }}
            />
          ) : null}
          <span className="block text-sm font-semibold text-ink">{opt.label}</span>
        </button>
      ))}
    </div>
  );
}

export default function ConfiguratorPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const [stepIndex, setStepIndex] = useState(0);
  const [config, setConfig] = useState({
    color: "black",
    wheels: "sport",
    interior: "black",
    studio: "showroom",
  });

  const step = STEPS[stepIndex];
  const stepLabels = [s.stepColor, s.stepWheels, s.stepInterior, s.stepStudio, s.stepSummary];
  const stepTitles = [s.selectColor, s.selectWheels, s.selectInterior, s.selectStudio, s.yourConfiguration];

  const next = () => {
    if (stepIndex >= STEPS.length - 1) {
      navigate("/app/capture?mode=camera");
      return;
    }
    setStepIndex((i) => i + 1);
  };

  const back = () => setStepIndex((i) => Math.max(0, i - 1));

  return (
    <div>
      <PageHeader title={s.configTitle} subtitle={stepTitles[stepIndex]} />

      <div className="mb-8 flex gap-2">
        {stepLabels.map((label, i) => (
          <div
            key={label}
            className={[
              "h-1.5 flex-1 rounded-full transition",
              i <= stepIndex ? "bg-gradient-to-r from-brand-600 to-violet-600" : "bg-slate-200",
            ].join(" ")}
            title={label}
          />
        ))}
      </div>

      <Card className="mb-6" elevated>
        {step === "summary" ? (
          <dl className="space-y-3 text-sm">
            {STEPS.slice(0, -1).map((key) => (
              <div key={key} className="flex justify-between border-b border-slate-100 pb-2">
                <dt className="text-ink-secondary">{stepLabels[STEPS.indexOf(key)]}</dt>
                <dd className="font-medium text-ink">
                  {OPTIONS[key].find((o) => o.id === config[key])?.label}
                </dd>
              </div>
            ))}
          </dl>
        ) : (
          <OptionGrid
            options={OPTIONS[step]}
            value={config[step]}
            onChange={(id) => setConfig((c) => ({ ...c, [step]: id }))}
            colorKey={step === "color"}
          />
        )}
      </Card>

      <div className="flex gap-3">
        {stepIndex > 0 ? (
          <Button variant="secondary" onClick={back}>
            {s.cancel}
          </Button>
        ) : null}
        <Button onClick={next}>
          {stepIndex >= STEPS.length - 1 ? s.confirmAndCapture : s.continueStep}
        </Button>
      </div>
    </div>
  );
}
