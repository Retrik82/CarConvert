import { useCallback, useState } from "react";
import { useNavigate } from "react-router-dom";
import { backgroundImageUrl, bundledPresetImagePath, BUNDLED_PRESET_SLUGS } from "../api/backgroundsApi";
import { useBackground } from "../contexts/BackgroundContext";
import { useStrings } from "../contexts/SettingsContext";
import AuthenticatedImage from "../components/AuthenticatedImage";
import BackgroundScenePreview, {
  resolvePresetFromSelection,
} from "../components/capture/BackgroundScenePreview";
import {
  BackgroundAngleFullscreen,
  BackgroundDetailModal,
} from "../components/backgrounds/BackgroundDetailSheet";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { PageHeader, Spinner } from "../components/layout/AppChrome";
import { IconCheck, IconStudio } from "../components/ui/Icons";

const PREVIEW_ANGLE = "three_quarter_left";

function presetPreviewImageUrl(preset) {
  const variant = preset.variants?.find((v) => v.angle === PREVIEW_ANGLE) || preset.variants?.[0];
  if (!variant) return null;

  const bundledById = bundledPresetImagePath(variant.id);
  if (bundledById) return bundledById;

  if (!preset.is_custom && BUNDLED_PRESET_SLUGS.includes(preset.slug) && variant.angle) {
    return `/backgrounds/presets/${preset.slug}/${variant.angle}.jpg`;
  }

  return backgroundImageUrl(variant.id);
}

function BackgroundCard({ preset, selected, onSelect, onPreview }) {
  const s = useStrings();
  const imageUrl = presetPreviewImageUrl(preset);

  const isSelected =
    selected?.presetSlug === preset.slug ||
    (preset.is_custom && selected?.userBackgroundId === preset.id);

  return (
    <Card
      onClick={onPreview}
      className={isSelected ? "ring-2 ring-brand-500" : ""}
      elevated={isSelected}
      padding={false}
    >
      <div className="relative aspect-[16/9] overflow-hidden rounded-t-[inherit] bg-surface-muted">
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
        {isSelected ? (
          <span className="absolute left-3 top-3 inline-flex items-center gap-1 rounded-full bg-brand-600 px-2.5 py-1 text-xs font-semibold text-white">
            <IconCheck className="h-3.5 w-3.5" />
            {s.recommended}
          </span>
        ) : null}
      </div>
      <div className="p-4">
        <h3 className="font-semibold text-ink">{preset.name}</h3>
        {preset.description ? (
          <p className="mt-1 text-sm text-ink-secondary">{preset.description}</p>
        ) : null}
        <Button
          size="sm"
          className="mt-3"
          onClick={(e) => {
            e.stopPropagation();
            onSelect(preset);
          }}
        >
          {isSelected ? s.useThisBackground : s.selectBackground}
        </Button>
      </div>
    </Card>
  );
}

export default function BackgroundsPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { presets, custom, selected, selectBackground, loading, reload } = useBackground();
  const [catalogError, setCatalogError] = useState(false);
  const [detailPreset, setDetailPreset] = useState(null);
  const [fullscreenAngle, setFullscreenAngle] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const selectedPreset = resolvePresetFromSelection(selected, presets, custom);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    setCatalogError(false);
    try {
      await reload();
    } catch {
      setCatalogError(true);
    } finally {
      setRefreshing(false);
    }
  }, [reload]);

  const handleSelect = (preset) => {
    selectBackground(preset);
  };

  return (
    <div>
      <PageHeader title={s.backgroundsTitle} subtitle={s.backgroundsIntro} />

      {(loading || refreshing) && (
        <div className="mb-4 h-1 overflow-hidden rounded-full bg-surface-muted">
          <div className="h-full w-1/3 animate-pulse bg-brand-500" />
        </div>
      )}

      {catalogError ? (
        <Card className="mb-4 flex items-center justify-between gap-3 p-3">
          <p className="text-sm text-ink-secondary">{s.errorGeneric}</p>
          <Button size="sm" variant="secondary" onClick={handleRefresh}>
            {s.retry}
          </Button>
        </Card>
      ) : null}

      {selectedPreset ? (
        <Card className="mb-6 flex items-center gap-3 p-3 ring-2 ring-brand-200" elevated>
          <div className="h-16 w-28 shrink-0 overflow-hidden rounded-xl">
            <BackgroundScenePreview preset={selectedPreset} angle={PREVIEW_ANGLE} />
          </div>
          <p className="flex-1 text-sm font-semibold text-ink">
            {s.backgroundSelected}: {selected.displayName}
          </p>
          <IconCheck className="h-5 w-5 shrink-0 text-green-600" />
        </Card>
      ) : null}

      {loading && !presets.length ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : (
        <>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold uppercase tracking-wide text-ink-tertiary">
              {s.sharedBackgrounds}
            </h2>
            <button type="button" className="text-xs font-medium text-brand-600" onClick={handleRefresh}>
              {s.retry}
            </button>
          </div>
          <div className="mb-8 grid gap-4 sm:grid-cols-2">
            {presets.map((preset) => (
              <BackgroundCard
                key={preset.id}
                preset={preset}
                selected={selected}
                onSelect={handleSelect}
                onPreview={() => setDetailPreset(preset)}
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
                    onPreview={() => setDetailPreset({ ...preset, is_custom: true })}
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

      <BackgroundDetailModal
        open={Boolean(detailPreset)}
        preset={detailPreset}
        isSelected={
          detailPreset &&
          (selected?.presetSlug === detailPreset.slug ||
            (detailPreset.is_custom && selected?.userBackgroundId === detailPreset.id))
        }
        onClose={() => setDetailPreset(null)}
        onSelect={() => {
          if (detailPreset) handleSelect(detailPreset);
          setDetailPreset(null);
        }}
        onAngleTap={(angle) => setFullscreenAngle({ preset: detailPreset, angle })}
      />

      <BackgroundAngleFullscreen
        open={Boolean(fullscreenAngle)}
        preset={fullscreenAngle?.preset}
        angle={fullscreenAngle?.angle}
        onClose={() => setFullscreenAngle(null)}
      />
    </div>
  );
}
