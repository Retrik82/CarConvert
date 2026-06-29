import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import {
  adminGetGenerationPrice,
  adminGetPricingEstimate,
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

function parsePriceInput(value) {
  const normalized = String(value).trim().replace(",", ".");
  if (!normalized) return { error: "empty" };
  const num = Number(normalized);
  if (Number.isNaN(num)) return { error: "invalid" };
  const parts = normalized.split(".");
  if (parts.length > 1 && parts[1].length > 2) return { error: "decimals" };
  if (num <= 0) return { error: "min" };
  if (num > 999.99) return { error: "max" };
  return { value: num };
}

export default function AdminPage() {
  const s = useStrings();
  const { isAdmin } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [currentPrice, setCurrentPrice] = useState(null);
  const [genPrice, setGenPrice] = useState("");
  const [estimate, setEstimate] = useState(null);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const [gen, est] = await Promise.all([
        adminGetGenerationPrice(),
        adminGetPricingEstimate().catch(() => null),
      ]);
      setCurrentPrice(gen);
      setGenPrice(gen.toFixed(2));
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
    if (saving) return;

    const parsed = parsePriceInput(genPrice);
    if (parsed.error) {
      const messages = {
        empty: s.priceRequired,
        invalid: s.priceInvalid,
        decimals: s.priceMaxDecimals,
        min: s.priceInvalid,
        max: s.priceTooHigh,
      };
      setError(messages[parsed.error] || s.priceInvalid);
      setSuccess("");
      return;
    }

    setSaving(true);
    setError("");
    setSuccess("");
    try {
      const saved = await adminSetGenerationPrice(parsed.value);
      setCurrentPrice(saved);
      setGenPrice(saved.toFixed(2));
      setSuccess(s.saved);
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

  const generationEstimate = estimate?.generation;
  const margin =
    generationEstimate && generationEstimate.actual_cost_max_usd > 0
      ? Math.round(
          (Number(genPrice) / Number(generationEstimate.actual_cost_max_usd) - 1) * 100,
        )
      : null;

  return (
    <div>
      <PageHeader title={s.adminPricing} />

      <Card className="mb-4">
        <h3 className="mb-2 font-semibold text-ink">{s.generationPrice}</h3>
        {currentPrice != null ? (
          <p className="mb-4 text-sm text-ink-secondary">
            {s.currentGenerationPrice(formatUsd(currentPrice))}
          </p>
        ) : null}
        <Input
          type="text"
          inputMode="decimal"
          value={genPrice}
          onChange={(e) => {
            setGenPrice(e.target.value);
            setSuccess("");
          }}
          placeholder="0.22"
        />
        {generationEstimate ? (
          <div className="mt-4 space-y-1 text-sm text-ink-secondary">
            <p>
              {s.costRange}: {formatUsd(generationEstimate.actual_cost_min_usd)} –{" "}
              {formatUsd(generationEstimate.actual_cost_max_usd)}
            </p>
            <p>
              {s.recommended}: {formatUsd(generationEstimate.recommended_price_usd)}
            </p>
            {margin != null ? (
              <p>
                {s.margin}: {margin >= 0 ? `+${margin}%` : `${margin}%`}
              </p>
            ) : null}
            <Button
              size="sm"
              variant="secondary"
              className="mt-2"
              onClick={() =>
                setGenPrice(Number(generationEstimate.recommended_price_usd).toFixed(2))
              }
            >
              {s.applyRecommended}
            </Button>
          </div>
        ) : null}
      </Card>

      <Button onClick={save} disabled={saving}>
        {saving ? s.loading : s.save}
      </Button>
      {success ? <p className="mt-3 text-sm text-green-600">{success}</p> : null}

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
