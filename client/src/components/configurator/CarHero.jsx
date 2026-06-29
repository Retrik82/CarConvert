/** BMW M4 hero with color tint — ported from car_hero.dart + car_overlay.dart */

const CAR_MODEL = "bmw_m4_g82";
const DEFAULT_VIEW = "side_right_neutral";

const COLOR_SWATCHES = {
  black: "#111827",
  white: "#F8FAFC",
  blue: "#2563EB",
  red: "#DC2626",
};

export function colorHex(colorId) {
  return COLOR_SWATCHES[colorId] || COLOR_SWATCHES.black;
}

export default function CarHero({ colorId = "black", height = 220, className = "" }) {
  const tint = colorHex(colorId);
  const src = `/cars/${CAR_MODEL}/${DEFAULT_VIEW}.png`;

  return (
    <div
      className={`relative w-full overflow-hidden ${className}`}
      style={{ height }}
    >
      <div
        className="absolute inset-x-[6%] bottom-[8%] top-[6%] flex items-end justify-center"
        style={{ backgroundColor: tint }}
      >
        <img
          src={src}
          alt=""
          className="max-h-full max-w-full object-contain object-bottom"
          style={{ mixBlendMode: "multiply", filter: "contrast(1.05)" }}
        />
      </div>
    </div>
  );
}
