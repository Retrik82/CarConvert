import { Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./contexts/AuthContext";
import { BackgroundProvider } from "./contexts/BackgroundContext";
import { SettingsProvider } from "./contexts/SettingsContext";
import { AuthLayout, GuestLayout, ProtectedLayout } from "./components/layout/Layouts";
import OnboardingPage from "./pages/OnboardingPage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import ForgotPasswordPage from "./pages/ForgotPasswordPage";
import ResetPasswordPage from "./pages/ResetPasswordPage";
import HomePage from "./pages/HomePage";
import BackgroundsPage from "./pages/BackgroundsPage";
import CapturePage from "./pages/CapturePage";
import ProcessingPage from "./pages/ProcessingPage";
import ResultPage from "./pages/ResultPage";
import MyCarsPage from "./pages/MyCarsPage";
import CarDetailPage from "./pages/CarDetailPage";
import ProfilePage from "./pages/ProfilePage";
import ConfiguratorPage from "./pages/ConfiguratorPage";
import AdminPage from "./pages/AdminPage";
import DownloadAppPage from "./pages/DownloadAppPage";
import NotFoundPage from "./pages/NotFoundPage";
import PublicShell from "./components/layout/PublicShell";

function AppRoutes() {
  return (
    <Routes>
      <Route element={<GuestLayout />}>
        <Route path="/" element={<Navigate to="/welcome" replace />} />
        <Route path="/welcome" element={<OnboardingPage />} />
        <Route element={<AuthLayout />}>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
        </Route>
      </Route>

      <Route
        element={
          <BackgroundProvider>
            <ProtectedLayout />
          </BackgroundProvider>
        }
      >
        <Route path="/app" element={<HomePage />} />
        <Route path="/app/backgrounds" element={<BackgroundsPage />} />
        <Route path="/app/configurator" element={<ConfiguratorPage />} />
        <Route path="/app/capture" element={<CapturePage />} />
        <Route path="/app/processing" element={<ProcessingPage />} />
        <Route path="/app/result" element={<ResultPage />} />
        <Route path="/app/cars" element={<MyCarsPage />} />
        <Route path="/app/cars/:carId" element={<CarDetailPage />} />
        <Route path="/app/profile" element={<ProfilePage />} />
        <Route path="/app/download" element={<DownloadAppPage />} />
        <Route path="/app/admin" element={<AdminPage />} />
      </Route>

      <Route
        path="/download"
        element={
          <PublicShell>
            <DownloadAppPage />
          </PublicShell>
        }
      />

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

export default function App() {
  return (
    <SettingsProvider>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </SettingsProvider>
  );
}
