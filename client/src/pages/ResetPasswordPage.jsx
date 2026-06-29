import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";
import Reveal from "../components/ui/Reveal";

export default function ResetPasswordPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { resetPassword } = useAuth();
  const [token, setToken] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await resetPassword(token.trim(), password);
      navigate("/login", { replace: true });
    } catch (err) {
      setError(userFacingError(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="page-enter">
      <Reveal>
        <AppLogo />
        <h1 className="mt-8 text-3xl font-bold tracking-tight text-ink">{s.resetPassword}</h1>
        <p className="mt-2 text-ink-secondary">{s.resetPasswordHint}</p>
      </Reveal>

      <Reveal delay={100}>
        <form onSubmit={handleSubmit} className="mt-8 space-y-5">
          <Input label={s.resetToken} value={token} onChange={(e) => setToken(e.target.value)} required />
          <Input
            label={s.newPassword}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            minLength={6}
            required
          />
          <Button type="submit" className="w-full" size="lg" loading={loading} disabled={loading}>
            {s.resetPassword}
          </Button>
        </form>
      </Reveal>

      <p className="mt-8 text-center text-sm text-ink-secondary">
        <Link to="/login" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.backToLogin}
        </Link>
      </p>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
