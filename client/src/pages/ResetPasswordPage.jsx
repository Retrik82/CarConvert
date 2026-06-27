import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";

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
    <>
      <div className="mb-8">
        <AppLogo />
        <h1 className="mt-8 text-2xl font-bold text-slate-900">{s.resetPassword}</h1>
        <p className="mt-2 text-sm text-slate-500">{s.resetPasswordHint}</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input label={s.resetToken} value={token} onChange={(e) => setToken(e.target.value)} required />
        <Input
          label={s.newPassword}
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          minLength={6}
          required
        />
        <Button type="submit" className="w-full" size="lg" disabled={loading}>
          {loading ? s.loading : s.resetPassword}
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-slate-500">
        <Link to="/login" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.backToLogin}
        </Link>
      </p>

      <Toast message={error} onClose={() => setError("")} />
    </>
  );
}
