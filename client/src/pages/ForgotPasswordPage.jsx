import { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";
import Reveal from "../components/ui/Reveal";

export default function ForgotPasswordPage() {
  const s = useStrings();
  const { forgotPassword } = useAuth();
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await forgotPassword(email.trim());
      setSent(true);
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
        <h1 className="mt-8 text-3xl font-bold tracking-tight text-ink">{s.forgotPassword}</h1>
        <p className="mt-2 text-ink-secondary">{s.forgotPasswordHint}</p>
      </Reveal>

      <Reveal delay={100} className="mt-8">
        {sent ? (
          <div className="rounded-input border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
            If the email exists, reset instructions have been sent.
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-5">
            <Input
              label={s.email}
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <Button type="submit" className="w-full" size="lg" loading={loading} disabled={loading}>
              {s.resetPassword}
            </Button>
          </form>
        )}
      </Reveal>

      <p className="mt-8 text-center text-sm text-ink-secondary">
        <Link to="/reset-password" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.resetPassword}
        </Link>
        {" · "}
        <Link to="/login" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.backToLogin}
        </Link>
      </p>

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
