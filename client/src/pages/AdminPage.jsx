import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import {
  adminGetCustomBackgroundPrice,
  adminGetGenerationPrice,
  adminGetPricingEstimate,
  adminSetCustomBackgroundPrice,
  adminSetGenerationPrice,
} from "../api/settingsApi";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { formatUsd, userFacingError } from "../utils/format";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Input from "../components/ui/Input";
import { PageHeader, Spinner } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

function PricingBlock({ title, value, onChange, estimate, onApplyRecommended }) {
  const s = useStrings();
  const margin =
    estimate && estimate.actual_cost_max_usd > 0
      ? Math.round((value / Number(estimate.actual_cost_max_usd) - 1) * 100)
      : null;

  return (
    <Card className="mb-4">
      <h3 className="mb-4 font-semibold text-slate-900">{title}</h3>
      <Input
        type="number"
        step="0.01"
        min="0.01"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
      {estimate ? (
        <div className="mt-4 space-y-1 text-sm text-slate-500">
          <p>
            {s.costRange}: {formatUsd(estimate.actual_cost_min_usd)} – {formatUsd(estimate.actual_cost_max_usd)}
          </p>
          <p>
            {s.recommended}: {formatUsd(estimate.recommended_price_usd)}
          </p>
          {margin != null ? (
            <p>
              {s.margin}: {margin >= 0 ? `+${margin}%` : `${margin}%`}
            </p>
          ) : null}
          <Button size="sm" variant="secondary" className="mt-2" onClick={onApplyRecommended}>
            Apply recommended
          </Button>
        </div>
      ) : null}
    </Card>
  );
}

export default function AdminPage() {
  const s = useStrings();
  const { isAdmin } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [genPrice, setGenPrice] = useState("0.10");
  const [bgPrice, setBgPrice] = useState("0.50");
  const [estimate, setEstimate] = useState(null);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const [gen, bg, est] = await Promise.all([
        adminGetGenerationPrice(),
        adminGetCustomBackgroundPrice(),
        adminGetPricingEstimate(),
      ]);
      setGenPrice(gen.toFixed(2));
      setBgPrice(bg.toFixed(2));
      setEstimate(est);
    } catch (e) {
      setError(userFacingError(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const save = async () => {
    setSaving(true);
    setError("");
    setSuccess("");
    try {
      await adminSetGenerationPrice(Number(genPrice));
      await adminSetCustomBackgroundPrice(Number(bgPrice));
      setSuccess(s.saved);
      load();
    } catch (e) {
      setError(userFacingError(e));
    } finally {
      setSaving(false);
    }
  };

  if (!isAdmin) return <Navigate to="/app" replace />;

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Spinner />
      </div>
    );
  }

  return (
    <div>
      <PageHeader title={s.adminPricing} />

      <PricingBlock
        title={s.generationPrice}
        value={genPrice}
        onChange={setGenPrice}
        estimate={estimate?.generation}
        onApplyRecommended={() =>
          setGenPrice(Number(estimate.generation.recommended_price_usd).toFixed(2))
        }
      />

      <PricingBlock
        title={s.customBackgroundPrice}
        value={bgPrice}
        onChange={setBgPrice}
        estimate={estimate?.custom_background}
        onApplyRecommended={() =>
          setBgPrice(Number(estimate.custom_background.recommended_price_usd).toFixed(2))
        }
      />

      <Button onClick={save} disabled={saving}>
        {saving ? s.loading : s.save}
      </Button>
      {success ? <p className="mt-3 text-sm text-green-600">{success}</p> : null}

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
