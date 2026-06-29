import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher } from "./AppChrome";
import Button from "../ui/Button";

export default function PublicShell({ children, wide = false }) {
  const s = useStrings();
  const { isLoggedIn } = useAuth();

  const shellClass = wide ? "shell-wide" : "mx-auto w-full max-w-3xl px-4 sm:px-6";

  return (
    <div className="page-bg flex min-h-screen flex-col">
      <header className="sticky top-0 z-40 glass-header">
        <div className={`flex w-full items-center justify-between gap-4 py-4 ${shellClass}`}>
          <Link to={isLoggedIn ? "/app" : "/welcome"}>
            <AppLogo size="sm" linkTo={false} />
          </Link>
          <div className="flex items-center gap-2 sm:gap-3">
            <LanguageSwitcher />
            {isLoggedIn ? (
              <Link to="/app">
                <Button size="sm" variant="secondary">
                  {s.navHome}
                </Button>
              </Link>
            ) : (
              <>
                <Link to="/login">
                  <Button size="sm" variant="ghost">
                    {s.login}
                  </Button>
                </Link>
                <Link to="/register">
                  <Button size="sm">{s.getStarted}</Button>
                </Link>
              </>
            )}
          </div>
        </div>
      </header>
      <main className={`flex-1 py-8 page-enter ${shellClass}`}>{children}</main>
    </div>
  );
}
