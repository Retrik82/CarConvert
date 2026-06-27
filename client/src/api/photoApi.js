import httpClient from "./httpClient";

export async function startSession() {
  const { data } = await httpClient.post("/session/start");
  return data.session_id;
}

export async function processPhoto(file, { sessionId, background } = {}) {
  const form = new FormData();
  form.append("image", file);
  if (sessionId) form.append("session_id", sessionId);
  if (background?.presetId) form.append("background_preset_id", background.presetId);
  if (background?.presetSlug) form.append("background_preset_slug", background.presetSlug);
  if (background?.userBackgroundId) form.append("user_background_id", background.userBackgroundId);

  const { data } = await httpClient.post("/photo/process", form, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return data;
}

export async function getPhotoResult(jobId) {
  const { data } = await httpClient.get(`/photo/result/${jobId}`);
  return data;
}

export async function getPhotoHistory() {
  const { data } = await httpClient.get("/photos/history");
  return data.items;
}
