import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { BUNDLED_PRESETS, fetchBackgroundCatalog } from "../api/backgroundsApi";
import { useAuth } from "./AuthContext";

const BG_KEY = "autocut_background";

const BackgroundContext = createContext(null);

function loadStoredBackground() {
  try {
    const raw = localStorage.getItem(BG_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function BackgroundProvider({ children }) {
  const { isLoggedIn } = useAuth();
  const [presets, setPresets] = useState(BUNDLED_PRESETS);
  const [custom, setCustom] = useState([]);
  const [selected, setSelectedState] = useState(loadStoredBackground);
  const [loading, setLoading] = useState(false);

  const selectBackground = useCallback((bg) => {
    const payload = {
      presetId: bg.is_custom ? undefined : bg.id,
      presetSlug: bg.slug,
      userBackgroundId: bg.is_custom ? bg.id : undefined,
      displayName: bg.name,
      slug: bg.slug,
    };
    setSelectedState(payload);
    localStorage.setItem(BG_KEY, JSON.stringify(payload));
  }, []);

  const loadCatalog = useCallback(async () => {
    if (!isLoggedIn) return;
    setLoading(true);
    try {
      const data = await fetchBackgroundCatalog();
      if (data.presets?.length) setPresets(data.presets);
      setCustom(data.custom || []);
    } catch (err) {
      throw err;
    } finally {
      setLoading(false);
    }
  }, [isLoggedIn]);

  useEffect(() => {
    loadCatalog().catch(() => {});
  }, [loadCatalog]);

  useEffect(() => {
    if (!selected && presets.length) {
      selectBackground(presets[0]);
    }
  }, [presets, selected, selectBackground]);

  const value = useMemo(
    () => ({
      presets,
      custom,
      selected,
      loading,
      selectBackground,
      reload: loadCatalog,
    }),
    [presets, custom, selected, loading, selectBackground, loadCatalog],
  );

  return <BackgroundContext.Provider value={value}>{children}</BackgroundContext.Provider>;
}

export function useBackground() {
  const ctx = useContext(BackgroundContext);
  if (!ctx) throw new Error("useBackground must be used within BackgroundProvider");
  return ctx;
}
