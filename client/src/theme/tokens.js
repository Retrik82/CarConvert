/** Design tokens mirrored from mobile/lib/core/theme (DesignTokens + AppTokens.light) */
export const tokens = {
  spacing: { 4: 4, 8: 8, 12: 12, 16: 16, 24: 24, 32: 32, 48: 48 },
  screenPaddingH: 24,
  minTapTarget: 48,
  radius: { card: 24, button: 16, input: 16, chip: 12, hero: 24 },
  colors: {
    primaryBlue: "#2563EB",
    primaryPurple: "#7C3AED",
    textDark: "#0F172A",
    textMuted: "#64748B",
    textTertiary: "#94A3B8",
    borderLight: "#E5E7EB",
    backgroundWhite: "#FFFFFF",
    backgroundElevated: "#F8FAFC",
    surfaceMuted: "#F1F5F9",
    accentMuted: "#DBEAFE",
    error: "#DC2626",
    success: "#16A34A",
    heroAmbient: "#EFF6FF",
  },
  motion: {
    fast: "200ms",
    normal: "300ms",
    slow: "550ms",
    easing: "cubic-bezier(0.65, 0, 0.35, 1)",
    easingOut: "cubic-bezier(0.33, 1, 0.68, 1)",
  },
  shadow: {
    card: "0 12px 32px -4px rgba(37, 99, 235, 0.06), 0 2px 8px rgba(15, 23, 42, 0.03)",
    elevated: "0 20px 48px -8px rgba(37, 99, 235, 0.1)",
    button: "0 6px 16px rgba(37, 99, 235, 0.25)",
    glow: "0 0 40px rgba(37, 99, 235, 0.12)",
  },
};

export const APP_VERSION = "1.0.0";
