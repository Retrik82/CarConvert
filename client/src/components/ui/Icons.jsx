/** Shared stroke icons — 24×24 viewBox, 1.75 stroke (matches app nav in Layouts.jsx) */

const defaults = {
  fill: "none",
  viewBox: "0 0 24 24",
  stroke: "currentColor",
  strokeWidth: 1.75,
  strokeLinecap: "round",
  strokeLinejoin: "round",
  "aria-hidden": true,
};

export function IconCheck(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M5 13l4 4L19 7" />
    </svg>
  );
}

export function IconArrowRight(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

export function IconDownload(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 4v12m0 0-4-4m4 4 4-4M4 20h16" />
    </svg>
  );
}

export function IconPalette(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 3c-4.5 0-8 3.5-8 8a4 4 0 004 4h1.5a1.5 1.5 0 001.4-2.1 2.5 2.5 0 012.4-1.9H14a3 3 0 003-3V9a6 6 0 00-3-6z" />
      <circle cx="8" cy="10" r="1" fill="currentColor" stroke="none" />
      <circle cx="10.5" cy="7" r="1" fill="currentColor" stroke="none" />
      <circle cx="14" cy="7.5" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function IconSettings(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 15a3 3 0 100-6 3 3 0 000 6z" />
      <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
    </svg>
  );
}

export function IconCamera(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M4 8h3l2-2h6l2 2h3a2 2 0 012 2v8a2 2 0 01-2 2H4a2 2 0 01-2-2v-8a2 2 0 012-2z" />
      <circle cx="12" cy="13" r="3.5" />
    </svg>
  );
}

export function IconGallery(props) {
  return (
    <svg {...defaults} {...props}>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <circle cx="8.5" cy="10.5" r="1.5" />
      <path d="M21 16l-5-5L7 19" />
    </svg>
  );
}

export function IconCar(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M5 11l1.5-4h11L19 11M5 11v6h2v-2h10v2h2v-6" />
      <circle cx="8" cy="15" r="1.5" />
      <circle cx="16" cy="15" r="1.5" />
    </svg>
  );
}

export function IconCarOutline(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M7 12h10M5 12l1.2-3.5h11.6L19 12" />
      <path d="M5 12v4h2v-1.5h10V16h2v-4" />
      <circle cx="8" cy="15.5" r="1.25" />
      <circle cx="16" cy="15.5" r="1.25" />
    </svg>
  );
}

export function IconSparkles(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 3l1.2 4.2L17.5 8.5 13.2 9.7 12 14l-1.2-4.3L6.5 8.5l4.3-1.3L12 3z" />
      <path d="M19 14l.7 2.3L22 17l-2.3.7L19 20l-.7-2.3L16 17l2.3-.7L19 14z" />
    </svg>
  );
}

export function IconImage(props) {
  return (
    <svg {...defaults} {...props}>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="M8 14l3-3 3 3 4-4 2 2" />
    </svg>
  );
}

export function IconStudio(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M4 18h16M6 18V8l6-4 6 4v10" />
      <path d="M10 12h4v6h-4z" />
    </svg>
  );
}

export function IconAndroid(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M8 6l-1.5-2.5M16 6l1.5-2.5M7 10h10v7a2 2 0 01-2 2H9a2 2 0 01-2-2v-7z" />
      <circle cx="10" cy="8.5" r="0.75" fill="currentColor" stroke="none" />
      <circle cx="14" cy="8.5" r="0.75" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function IconApple(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M16 8.5c-.8-1-2-1.5-3.2-1.4-.2 1.3.4 2.6 1.4 3.4-1 .9-2.2 1.5-3.5 1.4.3 1.9 1.8 3.3 3.7 3.3 2.2 0 3.8-1.8 4.8-3.8-1.2-.5-2.1-1.5-2.2-2.9z" />
      <path d="M13.2 4.5c.9 0 1.8.5 2.3 1.2-2 .3-3.5 1.8-3.7 3.7.9-.1 1.7-.5 2.3-1.1.6-.6 1-1.4.9-2.4-.3 0-.5-.1-.8-.1z" />
    </svg>
  );
}

export function IconShield(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 3l7 3v6c0 4.5-3.5 7.5-7 9-3.5-1.5-7-4.5-7-9V6l7-3z" />
      <path d="M9 12l2 2 4-4" />
    </svg>
  );
}

export function IconStar(props) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 3l2.4 5.5L20 9.5l-4.5 3.8 1.4 5.7L12 16.5 7.1 19l1.4-5.7L4 9.5l5.6-1L12 3z" />
    </svg>
  );
}

/** Brand mark — steering wheel + eye (transparent background) */
export function AppLogoMark({ className = "h-10 w-10", gradientId = "autocut-logo-grad" }) {
  const g = gradientId;
  return (
    <svg
      className={className}
      viewBox="0 0 48 48"
      role="img"
      aria-label="AutoCut"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id={g} x1="0" y1="48" x2="48" y2="0" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#2563EB" />
          <stop offset="100%" stopColor="#7C3AED" />
        </linearGradient>
      </defs>
      <line x1="10.405" y1="18.411" x2="9.641" y2="18.054" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="9.251" y1="22.016" x2="8.16" y2="21.814" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="9.037" y1="25.796" x2="7.665" y2="25.892" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="9.775" y1="29.51" x2="8.219" y2="30.03" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="11.42" y1="32.92" x2="9.821" y2="33.958" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="13.866" y1="35.809" x2="12.399" y2="37.41" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <line x1="16.958" y1="37.994" x2="15.814" y2="40.146" stroke={`url(#${g})`} strokeWidth="0.8" strokeLinecap="round" />
      <circle cx="24" cy="24.75" r="12.562" fill="none" stroke={`url(#${g})`} strokeWidth="1.78" />
      <path d="M 22.552,25.516 L 16.373,33.942 L 16.926,34.374 L 23.607,26.34 Z" fill={`url(#${g})`} />
      <path d="M 24.393,26.34 L 31.074,34.374 L 31.627,33.942 L 25.448,25.516 Z" fill={`url(#${g})`} />
      <path d="M 25.448,23.984 L 31.627,15.558 L 31.074,15.126 L 24.393,23.16 Z" fill={`url(#${g})`} />
      <path d="M 23.607,23.16 L 16.926,15.126 L 16.373,15.558 L 22.552,23.984 Z" fill={`url(#${g})`} />
      <path d="M 22.505,24.081 L 12.061,24.399 L 12.061,25.101 L 22.505,25.419 Z" fill={`url(#${g})`} />
      <circle cx="24" cy="24.75" r="2.719" fill={`url(#${g})`} />
      <circle cx="24" cy="24.75" r="1.969" fill="#FFFFFF" />
      <circle cx="24" cy="24.75" r="1.031" fill="#1E1B4B" />
      <circle cx="23.578" cy="24.281" r="0.6" fill="#FFFFFF" />
    </svg>
  );
}

/** Sized wrapper for icon slots in cards */
export function IconSlot({ children, highlighted, className = "" }) {
  return (
    <div
      className={[
        "flex shrink-0 items-center justify-center rounded-input transition",
        highlighted
          ? "bg-gradient-primary text-white shadow-button [&_svg]:text-white"
          : "bg-brand-50 text-brand-600",
        className,
      ].join(" ")}
    >
      {children}
    </div>
  );
}
