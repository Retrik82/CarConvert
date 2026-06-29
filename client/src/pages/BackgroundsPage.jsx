import { useNavigate } from "react-router-dom";
import { backgroundImageUrl, bundledPresetImagePath, BUNDLED_PRESET_SLUGS } from "../api/backgroundsApi";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import AuthenticatedImage from "../components/AuthenticatedImage";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { PageHeader, Spinner } from "../components/layout/AppChrome";
import { IconCheck, IconStudio } from "../components/ui/Icons";


function presetPreviewImageUrl(preset) {
  const variant = preset.variants?.[0];
  if (!variant) return null;

  const bundledById = bundledPresetImagePath(variant.id);
  if (bundledById) return bundledById;

  if (!preset.is_custom && BUNDLED_PRESET_SLUGS.includes(preset.slug) && variant.angle) {
    return `/backgrounds/presets/${preset.slug}/${variant.angle}.jpg`;
  }

  return backgroundImageUrl(variant.id);
}

function BackgroundCard({ preset, selected, onSelect }) {
  const imageUrl = presetPreviewImageUrl(preset);

  const isSelected =
    selected?.presetSlug === preset.slug ||
    (preset.is_custom && selected?.userBackgroundId === preset.id);

  return (
    <Card
      onClick={() => onSelect(preset)}
      className={isSelected ? "ring-2 ring-brand-500" : ""}
      elevated={isSelected}
    >
      <div className="mb-4 aspect-[16/9] overflow-hidden rounded-2xl bg-surface-muted">
        {imageUrl ? (
          imageUrl.startsWith("/backgrounds/presets/") ? (
            <img src={imageUrl} alt={preset.name} className="h-full w-full object-cover" loading="lazy" />
          ) : (
            <AuthenticatedImage src={imageUrl} alt={preset.name} className="h-full w-full object-cover" />
          )
        ) : (
          <div className="flex h-full items-center justify-center bg-surface-muted text-ink-tertiary">
            <IconStudio className="h-10 w-10" />
          </div>
        )}
      </div>
      <h3 className="font-semibold text-ink">{preset.name}</h3>
      {preset.description ? <p className="mt-1 text-sm text-ink-secondary">{preset.description}</p> : null}
      {isSelected ? (
        <span className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
          <IconCheck className="h-3.5 w-3.5" />
          Selected
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
          <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-ink-tertiary">
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
              <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-ink-tertiary">
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
