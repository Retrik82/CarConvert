import { useNavigate } from "react-router-dom";
import { backgroundImageUrl } from "../api/backgroundsApi";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import AuthenticatedImage from "../components/AuthenticatedImage";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { PageHeader, Spinner } from "../components/layout/AppChrome";

function BackgroundCard({ preset, selected, onSelect }) {
  const previewVariant = preset.variants?.[0];
  const imageUrl = previewVariant?.preview_url
    ? backgroundImageUrl(previewVariant.id)
    : null;

  const isSelected =
    selected?.presetSlug === preset.slug ||
    (preset.is_custom && selected?.userBackgroundId === preset.id);

  return (
    <Card
      onClick={() => onSelect(preset)}
      className={isSelected ? "ring-2 ring-brand-500" : ""}
      elevated={isSelected}
    >
      <div className="mb-4 aspect-[16/10] overflow-hidden rounded-2xl bg-slate-100">
        {imageUrl ? (
          <AuthenticatedImage src={imageUrl} alt={preset.name} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center bg-gradient-to-br from-slate-100 to-slate-200 text-4xl">
            🏎️
          </div>
        )}
      </div>
      <h3 className="font-semibold text-slate-900">{preset.name}</h3>
      {preset.description ? <p className="mt-1 text-sm text-slate-500">{preset.description}</p> : null}
      {isSelected ? (
        <span className="mt-3 inline-flex rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
          ✓ Selected
        </span>
      ) : null}
    </Card>
  );
}

export default function BackgroundsPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { presets, custom, selected, selectBackground, loading } = useBackground();

  const handleSelect = async (preset) => {
    selectBackground(preset);
  };

  return (
    <div>
      <PageHeader title={s.backgroundsTitle} subtitle={s.backgroundsIntro} />

      {loading ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : (
        <>
          <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-400">
            {s.sharedBackgrounds}
          </h2>
          <div className="mb-8 grid gap-4 sm:grid-cols-2">
            {presets.map((preset) => (
              <BackgroundCard
                key={preset.id}
                preset={preset}
                selected={selected}
                onSelect={handleSelect}
              />
            ))}
          </div>

          {custom.length > 0 ? (
            <>
              <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-400">
                {s.yourBackgrounds}
              </h2>
              <div className="mb-8 grid gap-4 sm:grid-cols-2">
                {custom.map((preset) => (
                  <BackgroundCard
                    key={preset.id}
                    preset={{ ...preset, is_custom: true }}
                    selected={selected}
                    onSelect={handleSelect}
                  />
                ))}
              </div>
            </>
          ) : null}
        </>
      )}

      <Button className="w-full sm:w-auto" onClick={() => navigate("/app")}>
        {s.useThisBackground}
      </Button>
    </div>
  );
}
