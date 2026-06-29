import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher } from "./AppChrome";
import Button from "../ui/Button";

export default function PublicShell({ children, wide = false }) {
  const s = useStrings();
  const { isLoggedIn } = useAuth();

  return (
    <div className="page-bg flex min-h-screen flex-col">
      <header className="sticky top-0 z-40 glass-header">
        <div
          className={`mx-auto flex w-full items-center justify-between gap-4 px-4 py-4 sm:px-6 ${wide ? "max-w-6xl lg:px-8" : "max-w-3xl"}`}
        >
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
              <Link to="/login">
                <Button size="sm" variant="secondary">
                  {s.login}
                </Button>
              </Link>
            )}
          </div>
        </div>
      </header>
      <main
        className={`mx-auto w-full flex-1 px-4 py-8 page-enter sm:px-6 ${wide ? "max-w-6xl lg:px-8" : "max-w-3xl"}`}
      >
        {children}
      </main>
    </div>
  );
}
