import { useMemo } from "react";

export function detectPlatform() {
  if (typeof navigator === "undefined") return "unknown";

  const ua = navigator.userAgent || navigator.vendor || "";
  const isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  const isAndroid = /Android/i.test(ua);

  if (isIOS) return "ios";
  if (isAndroid) return "android";
  return "desktop";
}

export function usePlatform() {
  return useMemo(() => detectPlatform(), []);
}
