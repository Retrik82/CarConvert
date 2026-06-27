import httpClient, { getApiBase } from "./httpClient";

export async function fetchMyCars() {
  const { data } = await httpClient.get("/my-cars");
  return data.cars;
}

export async function createCar(name) {
  const { data } = await httpClient.post("/my-cars", { name });
  return data;
}

export async function updateCarName(carId, name) {
  const { data } = await httpClient.patch(`/my-cars/${carId}`, { name });
  return data;
}

export async function deleteCar(carId) {
  await httpClient.delete(`/my-cars/${carId}`);
}

export async function saveRender(carId, { jobId, name }) {
  const form = new FormData();
  if (jobId) form.append("job_id", jobId);
  if (name) form.append("name", name);
  const { data } = await httpClient.post(`/my-cars/${carId}/renders`, form);
  return data;
}

export async function updateRenderName(carId, renderId, name) {
  const { data } = await httpClient.patch(`/my-cars/${carId}/renders/${renderId}`, { name });
  return data;
}

export async function deleteRender(carId, renderId) {
  await httpClient.delete(`/my-cars/${carId}/renders/${renderId}`);
}

export function renderImageUrl(carId, renderId, kind) {
  return `${getApiBase()}/my-cars/${carId}/renders/${renderId}/image/${kind}`;
}
