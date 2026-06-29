import httpClient, { getApiBase } from "./httpClient";

export async function fetchBackgroundCatalog() {
  const { data } = await httpClient.get("/backgrounds");
  return data;
}

const BUNDLED_PRESET_SLUGS = ["gray-showroom", "auto-workshop"];

export { BUNDLED_PRESET_SLUGS };

/** Static path for offline bundled presets — same JPEGs as mobile/assets/backgrounds/presets/. */
export function bundledPresetImagePath(variantId) {
  if (!variantId?.startsWith("local-")) return null;
  for (const slug of BUNDLED_PRESET_SLUGS) {
    const prefix = `local-${slug}-`;
    if (variantId.startsWith(prefix)) {
      const angle = variantId.slice(prefix.length);
      return `/backgrounds/presets/${slug}/${angle}.jpg`;
    }
  }
  return null;
}

export function backgroundImageUrl(variantId) {
  if (!variantId) return null;
  const bundled = bundledPresetImagePath(variantId);
  if (bundled) return bundled;
  return `${getApiBase()}/backgrounds/image/${variantId}`;
}

export const BUNDLED_PRESETS = [
  {
    id: "local-gray-showroom",
    slug: "gray-showroom",
    name: "Gray Showroom",
    description: "Minimalist gray studio with a central podium",
    is_custom: false,
    variants: [
      { id: "local-gray-showroom-three_quarter_left", angle: "three_quarter_left" },
    ],
  },
  {
    id: "local-auto-workshop",
    slug: "auto-workshop",
    name: "Auto Workshop",
    description: "Modern professional car service garage",
    is_custom: false,
    variants: [
      { id: "local-auto-workshop-three_quarter_left", angle: "three_quarter_left" },
    ],
  },
];
