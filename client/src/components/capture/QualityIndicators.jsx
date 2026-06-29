/** Quality score bars — ported from quality_indicators.dart */

import { captureChrome } from "../../theme/captureChrome";

function scoreColor(score) {
  if (score >= 0.75) return captureChrome.perfect;
  if (score >= 0.5) return captureChrome.accent;
  return captureChrome.warning;
}

function ScoreRow({ label, score }) {
  const color = scoreColor(score);
  const pct = Math.round(Math.max(0, Math.min(1, score)) * 100);

  return (
    <div className="flex items-center gap-2">
      <span className="w-[72px] shrink-0 text-xs" style={{ color: captureChrome.textMuted }}>
        {label}
      </span>
      <div className="h-1.5 flex-1 overflow-hidden rounded bg-white/10">
        <div className="h-full rounded transition-all" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="w-9 text-right text-xs font-semibold" style={{ color }}>
        {pct}%
      </span>
    </div>
  );
}

export default function QualityIndicators({ framingScore, lightingScore, focusScore, labels }) {
  return (
    <div
      className="space-y-3 rounded-2xl p-4"
      style={{
        background: captureChrome.surfaceGlass,
        border: `1px solid ${captureChrome.borderAccent}`,
      }}
    >
      <ScoreRow label={labels.framing} score={framingScore} />
      <ScoreRow label={labels.lighting} score={lightingScore} />
      <ScoreRow label={labels.focus} score={focusScore} />
    </div>
  );
}
