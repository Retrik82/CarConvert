import httpClient, { getApiBase } from "./httpClient";

export async function fetchBackgroundCatalog() {
  const { data } = await httpClient.get("/backgrounds");
  return data;
}

export function backgroundImageUrl(variantId) {
  if (!variantId) return null;
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
