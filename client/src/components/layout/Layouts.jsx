import { NavLink, Outlet, Navigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { IconCar, IconDownload, IconHome, IconSettings, IconUser } from "../ui/Icons";
import { AppLogo, LanguageSwitcher, Spinner } from "./AppChrome";

function NavIcon({ name, active }) {
  const className = `h-6 w-6 ${active ? "text-brand-600" : "text-ink-tertiary"}`;
  const strokeWidth = active ? 2.25 : 1.75;
  const icons = {
    home: <IconHome className={className} strokeWidth={strokeWidth} />,
    cars: <IconCar className={className} strokeWidth={strokeWidth} />,
    download: <IconDownload className={className} strokeWidth={strokeWidth} />,
    profile: <IconUser className={className} strokeWidth={strokeWidth} />,
    admin: <IconSettings className={className} strokeWidth={strokeWidth} />,
  };
  return icons[name] || null;
}

function NavItem({ to, label, icon, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        [
          "flex min-h-[48px] min-w-[64px] flex-col items-center justify-center gap-1 rounded-btn px-3 py-2 text-[11px] font-semibold transition-all duration-200 sm:min-w-0 sm:flex-row sm:gap-2 sm:px-4 sm:text-xs",
          isActive ? "bg-brand-50 text-brand-600" : "text-ink-tertiary hover:bg-surface-muted hover:text-ink",
        ].join(" ")
      }
    >
      {({ isActive }) => (
        <>
          <NavIcon name={icon} active={isActive} />
          <span>{label}</span>
        </>
      )}
    </NavLink>
  );
}

export function ProtectedLayout() {
  const { isLoggedIn, isAdmin, bootstrapping } = useAuth();
  const s = useStrings();

  if (bootstrapping) {
    return (
      <div className="page-bg flex min-h-screen items-center justify-center">
        <Spinner label={s.loading} />
      </div>
    );
  }

  if (!isLoggedIn) return <Navigate to="/welcome" replace />;

  return (
    <div className="page-bg mx-auto flex min-h-screen w-full max-w-6xl flex-col px-4 pb-28 pt-2 sm:px-6 lg:px-8">
      <header className="flex items-center justify-between py-4">
        <AppLogo linkTo={isAdmin ? "/app/admin" : "/app"} />
        <LanguageSwitcher />
      </header>

      <main className="flex-1 page-enter">
        <Outlet />
      </main>

      <nav
        className="fixed inset-x-0 bottom-0 z-40 glass-header"
        aria-label="App navigation"
      >
        <div className="mx-auto flex max-w-6xl items-center justify-around gap-0.5 px-2 py-2 sm:justify-center sm:gap-1">
          {isAdmin ? (
            <>
              <NavItem to="/app/admin" end label={s.navAdmin} icon="admin" />
              <NavItem to="/app/profile" label={s.navProfile} icon="profile" />
            </>
          ) : (
            <>
              <NavItem to="/app" end label={s.navHome} icon="home" />
              <NavItem to="/app/cars" label={s.navCars} icon="cars" />
              <NavItem to="/app/download" label={s.navDownload} icon="download" />
              <NavItem to="/app/profile" label={s.navProfile} icon="profile" />
            </>
          )}
        </div>
      </nav>
    </div>
  );
}

export function GuestLayout() {
  const { isLoggedIn, isAdmin, bootstrapping } = useAuth();

  if (bootstrapping) {
    return (
      <div className="page-bg flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (isLoggedIn) return <Navigate to={isAdmin ? "/app/admin" : "/app"} replace />;

  return <Outlet />;
}

export function AuthLayout() {
  return (
    <div className="page-bg mx-auto flex min-h-screen w-full max-w-lg flex-col px-6 py-8">
      <Outlet />
    </div>
  );
}
