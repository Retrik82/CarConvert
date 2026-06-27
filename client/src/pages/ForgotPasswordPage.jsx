import { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { useStrings } from "../contexts/SettingsContext";
import { userFacingError } from "../utils/format";
import { AppLogo } from "../components/layout/AppChrome";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Toast from "../components/ui/Toast";

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
    <>
      <div className="mb-8">
        <AppLogo />
        <h1 className="mt-8 text-2xl font-bold text-slate-900">{s.forgotPassword}</h1>
        <p className="mt-2 text-sm text-slate-500">{s.forgotPasswordHint}</p>
      </div>

      {sent ? (
        <div className="rounded-2xl border border-green-200 bg-green-50 p-4 text-sm text-green-800">
          If the email exists, reset instructions have been sent.
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label={s.email}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Button type="submit" className="w-full" size="lg" disabled={loading}>
            {loading ? s.loading : s.resetPassword}
          </Button>
        </form>
      )}

      <p className="mt-6 text-center text-sm text-slate-500">
        <Link to="/reset-password" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.resetPassword}
        </Link>
        {" · "}
        <Link to="/login" className="font-semibold text-brand-600 hover:text-brand-700">
          {s.backToLogin}
        </Link>
      </p>

      <Toast message={error} onClose={() => setError("")} />
    </>
  );
}
