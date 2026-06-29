/** Frame guide overlay — ported from frame_guide_painter.dart */

import { portraitFrameCrop } from "../../utils/frameCrop";
import { captureChrome } from "../../theme/captureChrome";

export default function FrameGuideOverlay({ crop = portraitFrameCrop, isPerfect = false }) {
  const borderColor = isPerfect ? captureChrome.perfect : captureChrome.accent;
  const dimAlpha = isPerfect ? 0.35 : 0.5;
  const { left, top, width, height } = crop;
  const gx = left * 100;
  const gy = top * 100;
  const gw = width * 100;
  const gh = height * 100;
  const cornerLen = 3.5;

  const corners = [
    [gx, gy, 1, 1],
    [gx + gw, gy, -1, 1],
    [gx, gy + gh, 1, -1],
    [gx + gw, gy + gh, -1, -1],
  ];

  return (
    <svg
      className="pointer-events-none absolute inset-0 h-full w-full"
      viewBox="0 0 100 100"
      preserveAspectRatio="none"
      aria-hidden
    >
      <defs>
        <mask id="capture-frame-mask">
          <rect width="100" height="100" fill="white" />
          <rect x={gx} y={gy} width={gw} height={gh} rx="2.2" fill="black" />
        </mask>
      </defs>
      <rect width="100" height="100" fill={`rgba(0,0,0,${dimAlpha})`} mask="url(#capture-frame-mask)" />
      <rect
        x={gx}
        y={gy}
        width={gw}
        height={gh}
        rx="2.2"
        fill="none"
        stroke={borderColor}
        strokeWidth="0.35"
        vectorEffect="non-scaling-stroke"
        opacity="0.9"
      />
      {!isPerfect ? (
        <rect
          x={gx}
          y={gy}
          width={gw}
          height={gh}
          rx="2.2"
          fill="none"
          stroke={captureChrome.accentGlow}
          strokeWidth="1"
          vectorEffect="non-scaling-stroke"
          opacity="0.6"
        />
      ) : null}
      <g stroke={borderColor} strokeWidth="0.5" strokeLinecap="round" vectorEffect="non-scaling-stroke">
        {corners.map(([cx, cy, dx, dy], i) => (
          <g key={i}>
            <line x1={cx} y1={cy} x2={cx + cornerLen * dx} y2={cy} />
            <line x1={cx} y1={cy} x2={cx} y2={cy + cornerLen * dy} />
          </g>
        ))}
      </g>
    </svg>
  );
}
