import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { getProfileOverride, saveProfileOverride } from "../repositories/profileRepository";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import { PageHeader } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

export default function EditProfilePage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { user, updateUserLocal } = useAuth();
  const fileRef = useRef(null);

  const [name, setName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!user) return;
    const override = getProfileOverride(user.id);
    setName(override?.display_name || user.display_name || "");
    setAvatarUrl(override?.avatar_data_url || null);
  }, [user]);

  const handleAvatarPick = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setAvatarUrl(reader.result);
    reader.readAsDataURL(file);
  };

  const handleSave = async () => {
    if (!user || !name.trim()) return;
    setSaving(true);
    setError("");
    try {
      saveProfileOverride(user.id, { displayName: name.trim(), avatarDataUrl: avatarUrl });
      updateUserLocal({ display_name: name.trim() });
      navigate("/app/profile");
    } catch {
      setError(s.errorGeneric);
    } finally {
      setSaving(false);
    }
  };

  const initials = (name || "?")
    .split(" ")
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <div>
      <PageHeader title={s.editProfileTitle} />

      <div className="mb-8 flex flex-col items-center">
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          className="relative mb-3 rounded-full bg-gradient-to-br from-brand-600 to-violet-600 p-1"
        >
          <div className="flex h-24 w-24 items-center justify-center overflow-hidden rounded-full bg-surface-muted text-2xl font-bold text-ink">
            {avatarUrl ? (
              <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              initials
            )}
          </div>
        </button>
        <p className="text-sm text-brand-600">{s.changeAvatar}</p>
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleAvatarPick} />
      </div>

      <Input label={s.displayName} value={name} onChange={(e) => setName(e.target.value)} />

      <div className="mt-6 flex gap-3">
        <Button variant="secondary" onClick={() => navigate("/app/profile")}>
          {s.cancel}
        </Button>
        <Button onClick={handleSave} disabled={saving || !name.trim()}>
          {saving ? s.loading : s.save}
        </Button>
      </div>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
