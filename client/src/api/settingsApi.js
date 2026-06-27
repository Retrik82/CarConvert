import httpClient from "./httpClient";

export async function getGenerationPrice() {
  const { data } = await httpClient.get("/settings/generation-price");
  return Number(data.price_usd);
}

export async function getCustomBackgroundPrice() {
  const { data } = await httpClient.get("/settings/custom-background-price");
  return Number(data.price_usd);
}

export async function adminGetGenerationPrice() {
  const { data } = await httpClient.get("/admin/settings/price");
  return Number(data.price_usd);
}

export async function adminSetGenerationPrice(priceUsd) {
  const { data } = await httpClient.put("/admin/settings/price", { price_usd: priceUsd });
  return Number(data.price_usd);
}

export async function adminGetCustomBackgroundPrice() {
  const { data } = await httpClient.get("/admin/settings/custom-background-price");
  return Number(data.price_usd);
}

export async function adminSetCustomBackgroundPrice(priceUsd) {
  const { data } = await httpClient.put("/admin/settings/custom-background-price", {
    price_usd: priceUsd,
  });
  return Number(data.price_usd);
}

export async function adminGetPricingEstimate() {
  const { data } = await httpClient.get("/admin/settings/pricing-estimate");
  return data;
}
