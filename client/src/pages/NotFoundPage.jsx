import { Link } from "react-router-dom";
import { useStrings } from "../contexts/SettingsContext";
import Button from "../components/ui/Button";
import Reveal from "../components/ui/Reveal";

export default function NotFoundPage() {
  const s = useStrings();

  return (
    <div className="page-bg flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <Reveal>
        <p className="text-8xl font-bold gradient-text">404</p>
        <h1 className="mt-4 text-2xl font-semibold text-ink">{s.notFound}</h1>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link to="/welcome">
            <Button>{s.goHome}</Button>
          </Link>
          <Link to="/download">
            <Button variant="secondary">{s.getTheApp}</Button>
          </Link>
        </div>
      </Reveal>
    </div>
  );
}
