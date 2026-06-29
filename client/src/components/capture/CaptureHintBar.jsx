/** Hint bar with direction arrows — ported from capture_hint_bar.dart */

import { Sparkles, CheckCircle, ArrowLeft, ArrowRight, ArrowUp, ArrowDown } from "lucide-react";
import { captureChrome } from "../../theme/captureChrome";

const ARROW_ICONS = {
  left: ArrowLeft,
  right: ArrowRight,
  up: ArrowUp,
  down: ArrowDown,
};

export default function CaptureHintBar({
  message,
  isPerfect = false,
  arrowDirection = "none",
  floating = false,
}) {
  const accent = isPerfect ? captureChrome.perfect : captureChrome.accent;
  const DirectionIcon = ARROW_ICONS[arrowDirection];
  const Icon = isPerfect ? CheckCircle : Sparkles;

  return (
    <div
      className="flex items-center justify-center gap-2 transition-all duration-300"
      style={{
        padding: floating ? "8px 12px" : "12px 16px",
        borderRadius: floating ? 12 : 16,
        background: isPerfect
          ? "rgba(22, 163, 74, 0.22)"
          : floating
            ? captureChrome.surfaceGlass
            : "rgba(255, 255, 255, 0.08)",
        border: `1px solid ${
          isPerfect ? "rgba(22, 163, 74, 0.7)" : floating ? captureChrome.borderAccent : captureChrome.borderGlass
        }`,
        boxShadow: floating && !isPerfect ? `0 4px 12px ${captureChrome.accentGlow}` : undefined,
      }}
    >
      <Icon className="h-5 w-5 shrink-0" style={{ color: accent }} />
      {DirectionIcon ? <DirectionIcon className="h-5 w-5 shrink-0" style={{ color: accent }} /> : null}
      <p
        className="min-w-0 flex-1 truncate text-center font-semibold leading-snug"
        style={{
          color: isPerfect ? captureChrome.perfect : captureChrome.textPrimary,
          fontSize: floating ? 13 : 14,
        }}
      >
        {message}
      </p>
    </div>
  );
}
