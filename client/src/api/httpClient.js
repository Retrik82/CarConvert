import axios from "axios";

const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:3001";

export function getApiBase() {
  return API_BASE.replace(/\/$/, "");
}

export function getWsBase() {
  const base = getApiBase();
  if (base.startsWith("https://")) return base.replace("https://", "wss://");
  if (base.startsWith("http://")) return base.replace("http://", "ws://");
  return `ws://${base}`;
}

const DEVICE_ID_KEY = "autocut_device_id";

function getDeviceId() {
  let id = localStorage.getItem(DEVICE_ID_KEY);
  if (!id) {
    id = crypto.randomUUID?.() || `web-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem(DEVICE_ID_KEY, id);
  }
  return id;
}

const httpClient = axios.create({
  baseURL: getApiBase(),
  timeout: 180000,
});

let accessToken = null;
let refreshToken = null;
let sessionId = null;
let refreshInFlight = null;
let onUnauthorized = null;

export function setAuthTokens({ access, refresh, session }) {
  accessToken = access ?? null;
  refreshToken = refresh ?? null;
  sessionId = session ?? null;
}

export function getAuthTokens() {
  return { accessToken, refreshToken, sessionId };
}

export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler;
}

httpClient.interceptors.request.use((config) => {
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  if (sessionId) {
    config.headers["X-Session-Id"] = sessionId;
  }
  config.headers["X-Device-Id"] = getDeviceId();
  config.headers["X-Device-Name"] = "Web";
  return config;
});

httpClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config;
    if (!original || original._retry || error.response?.status !== 401 || !refreshToken) {
      return Promise.reject(error);
    }
    original._retry = true;

    if (!refreshInFlight) {
      refreshInFlight = (async () => {
        try {
          const { data } = await axios.post(
            `${getApiBase()}/auth/refresh`,
            { refresh_token: refreshToken },
            {
              headers: {
                "Content-Type": "application/json",
                "X-Device-Id": getDeviceId(),
                "X-Device-Name": "Web",
              },
            },
          );
          accessToken = data.access_token;
          refreshToken = data.refresh_token;
          sessionId = data.session_id ?? sessionId;
          return true;
        } catch {
          accessToken = null;
          refreshToken = null;
          sessionId = null;
          onUnauthorized?.();
          return false;
        } finally {
          refreshInFlight = null;
        }
      })();
    }

    const ok = await refreshInFlight;
    if (!ok) return Promise.reject(error);
    return httpClient(original);
  },
);

export async function fetchAuthenticatedBlob(path) {
  const response = await httpClient.get(path, { responseType: "blob" });
  return URL.createObjectURL(response.data);
}

export default httpClient;
