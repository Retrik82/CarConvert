import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
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
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(null);

  useEffect(() => {
    refreshUser().catch(() => {});
    getGenerationPrice().then(setPrice).catch(() => {});
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
