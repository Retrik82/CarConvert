import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher } from "./AppChrome";
import Button from "../ui/Button";

export default function PublicShell({ children }) {
  const s = useStrings();
  const { isLoggedIn } = useAuth();

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-3xl flex-col px-4 py-6 sm:px-6">
      <header className="mb-6 flex items-center justify-between gap-4">
        <Link to={isLoggedIn ? "/app" : "/welcome"}>
          <AppLogo />
        </Link>
        <div className="flex items-center gap-2">
          <LanguageSwitcher />
          {isLoggedIn ? (
            <Link to="/app">
              <Button size="sm" variant="secondary">
                {s.navHome}
              </Button>
            </Link>
          ) : (
            <Link to="/login">
              <Button size="sm" variant="secondary">
                {s.login}
              </Button>
            </Link>
          )}
        </div>
      </header>
      <main className="flex-1">{children}</main>
    </div>
  );
}
