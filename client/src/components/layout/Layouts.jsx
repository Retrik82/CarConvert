import { NavLink, Outlet, Navigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher, Spinner } from "./AppChrome";

function NavIcon({ name, active }) {
  const color = active ? "text-brand-600" : "text-ink-tertiary";
  const icons = {
    home: (
      <svg className={`h-6 w-6 ${color}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l9-9 9 9M5 10v10a1 1 0 001 1h3m10-11v10a1 1 0 01-1 1h-3m-4 0h4" />
      </svg>
    ),
    cars: (
      <svg className={`h-6 w-6 ${color}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zm10 0a2 2 0 11-4 0 2 2 0 014 0zM5 11l1-4h12l1 4M7 11h10" />
      </svg>
    ),
    download: (
      <svg className={`h-6 w-6 ${color}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v12m0 0l-4-4m4 4l4-4M4 20h16" />
      </svg>
    ),
    profile: (
      <svg className={`h-6 w-6 ${color}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM6 21v-1a6 6 0 0112 0v1" />
      </svg>
    ),
    admin: (
      <svg className={`h-6 w-6 ${color}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
    ),
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
        <AppLogo linkTo="/app" />
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
          <NavItem to="/app" end label={s.navHome} icon="home" />
          <NavItem to="/app/cars" label={s.navCars} icon="cars" />
          <NavItem to="/app/download" label={s.navDownload} icon="download" />
          <NavItem to="/app/profile" label={s.navProfile} icon="profile" />
          {isAdmin ? <NavItem to="/app/admin" label={s.navAdmin} icon="admin" /> : null}
        </div>
      </nav>
    </div>
  );
}

export function GuestLayout() {
  const { isLoggedIn, bootstrapping } = useAuth();

  if (bootstrapping) {
    return (
      <div className="page-bg flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (isLoggedIn) return <Navigate to="/app" replace />;

  return <Outlet />;
}

export function AuthLayout() {
  return (
    <div className="page-bg mx-auto flex min-h-screen w-full max-w-lg flex-col px-6 py-8">
      <Outlet />
    </div>
  );
}
