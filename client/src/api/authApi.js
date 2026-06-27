import httpClient, { setAuthTokens } from "./httpClient";

const STORAGE_KEY = "autocut_session";

export function loadStoredSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function persistSession({ refreshToken, sessionId, user }) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ refreshToken, sessionId, user }));
}

export function clearStoredSession() {
  localStorage.removeItem(STORAGE_KEY);
}

export async function bootstrapFromStorage() {
  const stored = loadStoredSession();
  if (!stored?.refreshToken) return null;

  setAuthTokens({ refresh: stored.refreshToken, session: stored.sessionId });

  try {
    const { data } = await httpClient.post("/auth/refresh", {
      refresh_token: stored.refreshToken,
    });
    setAuthTokens({
      access: data.access_token,
      refresh: data.refresh_token,
      session: data.session_id,
    });
    persistSession({
      refreshToken: data.refresh_token,
      sessionId: data.session_id,
      user: data.user,
    });
    return data;
  } catch {
    clearStoredSession();
    setAuthTokens({ access: null, refresh: null, session: null });
    return null;
  }
}

export async function login(email, password) {
  const { data } = await httpClient.post("/auth/login", {
    email,
    password,
    device_id: localStorage.getItem("autocut_device_id"),
    device_name: "Web",
  });
  setAuthTokens({
    access: data.access_token,
    refresh: data.refresh_token,
    session: data.session_id,
  });
  persistSession({
    refreshToken: data.refresh_token,
    sessionId: data.session_id,
    user: data.user,
  });
  return data;
}

export async function register(email, password, displayName) {
  const { data } = await httpClient.post("/auth/register", {
    email,
    password,
    display_name: displayName,
    device_id: localStorage.getItem("autocut_device_id"),
    device_name: "Web",
  });
  setAuthTokens({
    access: data.access_token,
    refresh: data.refresh_token,
    session: data.session_id,
  });
  persistSession({
    refreshToken: data.refresh_token,
    sessionId: data.session_id,
    user: data.user,
  });
  return data;
}

export async function logout() {
  const stored = loadStoredSession();
  if (stored?.refreshToken) {
    try {
      await httpClient.post("/auth/logout", { refresh_token: stored.refreshToken });
    } catch {
      /* ignore */
    }
  }
  clearStoredSession();
  setAuthTokens({ access: null, refresh: null, session: null });
}

export async function fetchCurrentUser() {
  const { data } = await httpClient.get("/auth/me");
  const stored = loadStoredSession();
  if (stored) {
    persistSession({ ...stored, user: data });
  }
  return data;
}

export async function forgotPassword(email) {
  await httpClient.post("/auth/forgot-password", { email });
}

export async function resetPassword(token, newPassword) {
  await httpClient.post("/auth/reset-password", { token, new_password: newPassword });
}

export async function fetchSessions() {
  const { data } = await httpClient.get("/auth/sessions");
  return data.sessions;
}

export async function revokeSession(sessionId) {
  await httpClient.delete(`/auth/sessions/${sessionId}`);
}

export async function logoutAllDevices(keepCurrent = true) {
  await httpClient.post("/auth/logout-all", { keep_current_session: keepCurrent });
}
