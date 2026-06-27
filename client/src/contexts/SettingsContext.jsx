import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { getStrings, LANGUAGES } from "../i18n";

const LANG_KEY = "autocut_lang";

const SettingsContext = createContext(null);

export function SettingsProvider({ children }) {
  const [lang, setLangState] = useState(() => localStorage.getItem(LANG_KEY) || "en");

  useEffect(() => {
    localStorage.setItem(LANG_KEY, lang);
    document.documentElement.lang = lang;
  }, [lang]);

  const setLang = (code) => setLangState(code);

  const strings = useMemo(() => getStrings(lang), [lang]);

  const value = useMemo(
    () => ({ lang, setLang, strings, languages: LANGUAGES }),
    [lang, strings],
  );

  return <SettingsContext.Provider value={value}>{children}</SettingsContext.Provider>;
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}

export function useStrings() {
  return useSettings().strings;
}
