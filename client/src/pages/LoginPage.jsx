import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";

export default function LoginPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await login(email.trim(), password);
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
        <h1 className="mt-8 text-2xl font-bold text-slate-900">{s.login}</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label={s.emailOrUsername}
          type="text"
          autoComplete="username"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <Input
          label={s.password}
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <div className="flex justify-end">
          <Link to="/forgot-password" className="text-sm font-medium text-brand-600 hover:text-brand-700">
            {s.forgotPassword}
          </Link>
        </div>

        <Button type="submit" className="w-full" size="lg" disabled={loading}>
          {loading ? s.loading : s.login}
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-slate-500">
        {s.loginNoAccount}{" "}
        <Link to="/register" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.register}
        </Link>
      </p>

      <Toast message={error} onClose={() => setError("")} />
    </>
  );
}
