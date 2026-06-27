import { NavLink, Outlet, Navigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { useStrings } from "../../contexts/SettingsContext";
import { AppLogo, LanguageSwitcher, Spinner } from "./AppChrome";

function NavItem({ to, label, icon }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        [
          "flex flex-col items-center gap-1 rounded-2xl px-4 py-2 text-xs font-semibold transition sm:flex-row sm:gap-2 sm:px-4 sm:py-2.5 sm:text-sm",
          isActive ? "bg-brand-50 text-brand-700" : "text-slate-500 hover:bg-slate-50 hover:text-slate-800",
        ].join(" ")
      }
    >
      <span className="text-lg sm:text-base">{icon}</span>
      <span>{label}</span>
    </NavLink>
  );
}

export function ProtectedLayout() {
  const { isLoggedIn, isAdmin, bootstrapping } = useAuth();
  const s = useStrings();

  if (bootstrapping) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (!isLoggedIn) return <Navigate to="/welcome" replace />;

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-4 pb-24 pt-2 sm:px-6 lg:px-8">
      <header className="flex items-center justify-between py-4">
        <AppLogo />
        <LanguageSwitcher />
      </header>

      <main className="flex-1">
        <Outlet />
      </main>

      <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-slate-200/80 bg-white/90 backdrop-blur-xl">
        <div className="mx-auto flex max-w-6xl items-center justify-around gap-1 px-2 py-2 sm:justify-center sm:gap-2">
          <NavItem to="/app" end label={s.navHome} icon="🏠" />
          <NavItem to="/app/cars" label={s.navCars} icon="🚗" />
          <NavItem to="/app/download" label={s.navDownload} icon="📲" />
          <NavItem to="/app/profile" label={s.navProfile} icon="👤" />
          {isAdmin ? <NavItem to="/app/admin" label={s.navAdmin} icon="⚙️" /> : null}
        </div>
      </nav>
    </div>
  );
}

export function GuestLayout() {
  const { isLoggedIn, bootstrapping } = useAuth();

  if (bootstrapping) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (isLoggedIn) return <Navigate to="/app" replace />;

  return <Outlet />;
}

export function AuthLayout({ children }) {
  return (
    <div className="mx-auto flex min-h-screen w-full max-w-lg flex-col px-4 py-8 sm:px-6">
      <Outlet />
    </div>
  );
}
