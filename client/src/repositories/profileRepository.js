/** Local profile overrides (display name + avatar) — mirrors ProfileRepository */

const KEY = "autocut_profile_override";

function loadAll() {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function saveAll(data) {
  localStorage.setItem(KEY, JSON.stringify(data));
}

export function getProfileOverride(userId) {
  if (!userId) return null;
  return loadAll()[userId] || null;
}

export function saveProfileOverride(userId, { displayName, avatarDataUrl }) {
  if (!userId) return;
  const all = loadAll();
  all[userId] = {
    display_name: displayName,
    avatar_data_url: avatarDataUrl || all[userId]?.avatar_data_url || null,
  };
  saveAll(all);
}

export function getAvatarUrl(userId) {
  return getProfileOverride(userId)?.avatar_data_url || null;
}
