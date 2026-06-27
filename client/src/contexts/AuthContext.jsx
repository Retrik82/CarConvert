import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  bootstrapFromStorage,
  fetchCurrentUser,
  login as apiLogin,
  logout as apiLogout,
  register as apiRegister,
  forgotPassword,
  resetPassword,
  persistSession,
  loadStoredSession,
} from "../api/authApi";
import { setUnauthorizedHandler } from "../api/httpClient";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [bootstrapping, setBootstrapping] = useState(true);
  const [error, setError] = useState("");

  const refreshUser = useCallback(async () => {
    const data = await fetchCurrentUser();
    setUser(data);
    return data;
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => {
      setUser(null);
    });

    (async () => {
      try {
        const data = await bootstrapFromStorage();
        if (data?.user) setUser(data.user);
      } finally {
        setBootstrapping(false);
      }
    })();
  }, []);

  const login = useCallback(async (email, password) => {
    setError("");
    const data = await apiLogin(email, password);
    setUser(data.user);
    return data;
  }, []);

  const register = useCallback(async (email, password, displayName) => {
    setError("");
    const data = await apiRegister(email, password, displayName);
    setUser(data.user);
    return data;
  }, []);

  const logout = useCallback(async () => {
    await apiLogout();
    setUser(null);
  }, []);

  const updateUserLocal = useCallback((patch) => {
    setUser((prev) => {
      if (!prev) return prev;
      const next = { ...prev, ...patch };
      const stored = loadStoredSession();
      if (stored) persistSession({ ...stored, user: next });
      return next;
    });
  }, []);

  const value = useMemo(
    () => ({
      user,
      isLoggedIn: Boolean(user),
      isAdmin: Boolean(user?.is_admin),
      bootstrapping,
      error,
      setError,
      login,
      register,
      logout,
      refreshUser,
      updateUserLocal,
      forgotPassword,
      resetPassword,
    }),
    [user, bootstrapping, error, login, register, logout, refreshUser, updateUserLocal],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
