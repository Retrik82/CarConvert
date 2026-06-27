import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";

export default function RegisterPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { register } = useAuth();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await register(email.trim(), password, displayName.trim());
      navigate("/app", { replace: true });
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
        <h1 className="mt-8 text-2xl font-bold text-slate-900">{s.createAccount}</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label={s.displayName}
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          required
        />
        <Input
          label={s.email}
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <Input
          label={s.password}
          type="password"
          autoComplete="new-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          minLength={6}
          required
        />

        <Button type="submit" className="w-full" size="lg" disabled={loading}>
          {loading ? s.loading : s.register}
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
