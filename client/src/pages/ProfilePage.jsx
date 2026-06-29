import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { fetchSessions, logoutAllDevices, revokeSession } from "../api/authApi";
import { getGenerationPrice } from "../api/settingsApi";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { getAvatarUrl } from "../repositories/profileRepository";
import { formatDate, formatUsd } from "../utils/format";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import { ConfirmModal } from "../components/ui/Modal";
import { LanguageSwitcher, PageHeader } from "../components/layout/AppChrome";

export default function ProfilePage() {
  const s = useStrings();
  const { user, logout, refreshUser } = useAuth();
  const [price, setPrice] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(null);

  useEffect(() => {
    refreshUser().catch(() => {});
    getGenerationPrice().then(setPrice).catch(() => {});
    fetchSessions().then(setSessions).catch(() => {});
  }, [refreshUser]);

  useEffect(() => {
    if (user?.id) setAvatarUrl(getAvatarUrl(user.id));
  }, [user]);

  const initials = (user?.display_name || "?")
    .split(" ")
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <div>
      <PageHeader title={s.profile} />

      <Card className="mb-6 text-center" elevated>
        <div className="mx-auto mb-4 flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-gradient-to-br from-brand-600 to-violet-600 text-2xl font-bold text-white shadow-lg">
          {avatarUrl ? (
            <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            initials
          )}
        </div>
        <h2 className="text-xl font-semibold text-ink">{user?.display_name}</h2>
        <p className="text-sm text-ink-secondary">{user?.email}</p>
        <Link to="/app/profile/edit" className="mt-4 inline-block">
          <Button size="sm" variant="secondary">
            {s.editProfile}
          </Button>
        </Link>
        <div className="mt-4 inline-flex rounded-full bg-brand-50 px-4 py-2 text-sm font-semibold text-brand-700">
          {s.balance}: {formatUsd(user?.balance)}
        </div>
        {price != null ? (
          <p className="mt-2 text-xs text-ink-tertiary">
            {s.estimatedPrice}: {formatUsd(price)}
          </p>
        ) : null}
        {user?.created_at ? (
          <p className="mt-2 text-xs text-ink-tertiary">
            {s.memberSince} {formatDate(user.created_at)}
          </p>
        ) : null}
      </Card>

      <Card className="mb-6">
        <h3 className="mb-3 font-semibold text-ink">{s.language}</h3>
        <LanguageSwitcher />
      </Card>

      {sessions.length > 0 ? (
        <Card className="mb-6">
          <h3 className="mb-4 font-semibold text-ink">{s.sessions}</h3>
          <ul className="space-y-3">
            {sessions.map((session) => (
              <li
                key={session.id}
                className="flex items-center justify-between gap-3 rounded-2xl border border-slate-100 bg-surface-muted/50 px-4 py-3 text-sm"
              >
                <div>
                  <p className="font-medium text-ink">
                    {session.device_name || "Unknown device"}
                    {session.is_current ? " (current)" : ""}
                  </p>
                  <p className="text-xs text-ink-tertiary">{formatDate(session.last_used_at || session.created_at)}</p>
                </div>
                {!session.is_current ? (
                  <Button size="sm" variant="ghost" onClick={() => revokeSession(session.id).then(() => fetchSessions().then(setSessions))}>
                    {s.revokeSession}
                  </Button>
                ) : null}
              </li>
            ))}
          </ul>
          <Button
            variant="secondary"
            size="sm"
            className="mt-4"
            onClick={() => logoutAllDevices(true)}
          >
            Logout other devices
          </Button>
        </Card>
      ) : null}

      <Button variant="danger" className="w-full" onClick={() => setLogoutOpen(true)}>
        {s.logout}
      </Button>

      <ConfirmModal
        open={logoutOpen}
        title={s.logoutConfirmTitle}
        body={s.logoutConfirmBody}
        confirmLabel={s.logout}
        cancelLabel={s.cancel}
        onConfirm={logout}
        onClose={() => setLogoutOpen(false)}
      />
    </div>
  );
}
