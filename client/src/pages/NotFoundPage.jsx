import { Link } from "react-router-dom";
import { useStrings } from "../contexts/SettingsContext";
import Button from "../components/ui/Button";

export default function NotFoundPage() {
  const s = useStrings();

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <p className="text-6xl font-bold text-slate-200">404</p>
      <h1 className="mt-4 text-2xl font-semibold text-slate-900">{s.notFound}</h1>
      <Link to="/app" className="mt-6">
        <Button>{s.goHome}</Button>
      </Link>
    </div>
  );
}
