import {
  ArrowRight,
  Building2,
  Camera,
  Car,
  Check,
  Download,
  Image,
  Images,
  Palette,
  Settings,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Star,
  Tablet,
  ChevronsLeftRight,
} from "lucide-react";

const defaults = {
  strokeWidth: 1.75,
  "aria-hidden": true,
};

function LucideIcon({ icon: Icon, ...props }) {
  return <Icon {...defaults} {...props} />;
}

export function IconCheck(props) {
  return <LucideIcon icon={Check} {...props} />;
}

export function IconArrowRight(props) {
  return <LucideIcon icon={ArrowRight} {...props} />;
}

export function IconDownload(props) {
  return <LucideIcon icon={Download} {...props} />;
}

export function IconPalette(props) {
  return <LucideIcon icon={Palette} {...props} />;
}

export function IconSettings(props) {
  return <LucideIcon icon={Settings} {...props} />;
}

export function IconCamera(props) {
  return <LucideIcon icon={Camera} {...props} />;
}

export function IconGallery(props) {
  return <LucideIcon icon={Images} {...props} />;
}

export function IconCar(props) {
  return <LucideIcon icon={Car} {...props} />;
}

export function IconCarOutline(props) {
  return <LucideIcon icon={Car} {...props} />;
}

export function IconSparkles(props) {
  return <LucideIcon icon={Sparkles} {...props} />;
}

export function IconImage(props) {
  return <LucideIcon icon={Image} {...props} />;
}

export function IconStudio(props) {
  return <LucideIcon icon={Building2} {...props} />;
}

export function IconAndroid(props) {
  return <LucideIcon icon={Smartphone} {...props} />;
}

export function IconApple(props) {
  return <LucideIcon icon={Tablet} {...props} />;
}

export function IconShield(props) {
  return <LucideIcon icon={ShieldCheck} {...props} />;
}

export function IconStar(props) {
  return <LucideIcon icon={Star} {...props} />;
}

export function IconChevronsLeftRight(props) {
  return <LucideIcon icon={ChevronsLeftRight} {...props} />;
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
