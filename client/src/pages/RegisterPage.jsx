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
      const data = await register(email.trim(), password, displayName.trim());
      navigate(data.user?.is_admin ? "/app/admin" : "/app", { replace: true });
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
        <h1 className="mt-8 text-3xl font-bold tracking-tight text-ink">{s.createAccount}</h1>
        <p className="mt-2 text-ink-secondary">{s.appTagline}</p>
      </Reveal>

      <Reveal delay={100}>
        <form onSubmit={handleSubmit} className="mt-8 space-y-5">
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

          <Button type="submit" className="w-full" size="lg" loading={loading} disabled={loading}>
            {s.register}
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
