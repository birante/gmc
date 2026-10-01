import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { api, decodeToken, tokenStore, UNAUTHORIZED_EVENT } from '../api/client.js';
import { useToast } from './ToastContext.jsx';

export const AuthContext = createContext(null);

const MAX_TIMEOUT = 2 ** 31 - 1;

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(() => Boolean(tokenStore.get()));
  const { showToast } = useToast();
  const expiryTimer = useRef(null);

  const clearSession = useCallback(() => {
    tokenStore.clear();
    setUser(null);
    if (expiryTimer.current) clearTimeout(expiryTimer.current);
  }, []);

  // Planifie une déconnexion automatique à l'expiration du jeton.
  const scheduleExpiry = useCallback(
    (token) => {
      if (expiryTimer.current) clearTimeout(expiryTimer.current);
      const payload = decodeToken(token);
      if (!payload?.exp) return;
      const ms = payload.exp * 1000 - Date.now();
      if (ms <= 0) {
        clearSession();
        return;
      }
      expiryTimer.current = setTimeout(() => {
        clearSession();
        showToast('Votre session a expiré, veuillez vous reconnecter.', 'info');
      }, Math.min(ms, MAX_TIMEOUT));
    },
    [clearSession, showToast]
  );

  const startSession = useCallback(
    ({ token, user: u }) => {
      tokenStore.set(token);
      setUser(u);
      scheduleExpiry(token);
      return u;
    },
    [scheduleExpiry]
  );

  // Restauration de la session au rechargement de la page
  useEffect(() => {
    const token = tokenStore.get();
    if (!token) return undefined;
    let cancelled = false;
    api
      .me()
      .then(({ user: u }) => {
        if (cancelled) return;
        setUser(u);
        scheduleExpiry(token);
      })
      .catch(() => !cancelled && clearSession())
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [clearSession, scheduleExpiry]);

  // Toute réponse 401 de l'API déconnecte l'utilisateur
  useEffect(() => {
    const onUnauthorized = (e) => {
      setUser((current) => {
        if (current) showToast(e.detail || 'Session expirée, veuillez vous reconnecter.', 'info');
        return null;
      });
      if (expiryTimer.current) clearTimeout(expiryTimer.current);
    };
    window.addEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
    return () => window.removeEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
  }, [showToast]);

  useEffect(() => () => expiryTimer.current && clearTimeout(expiryTimer.current), []);

  const login = useCallback(async (email, password) => startSession(await api.login(email, password)), [startSession]);
  const register = useCallback(async (payload) => startSession(await api.register(payload)), [startSession]);
  const logout = useCallback(() => {
    api.logout();
    clearSession();
  }, [clearSession]);
  const updateProfile = useCallback(async (payload) => {
    const { user: u } = await api.updateMe(payload);
    setUser(u);
    return u;
  }, []);

  const value = useMemo(
    () => ({ user, loading, isAuthenticated: Boolean(user), login, register, logout, updateProfile }),
    [user, loading, login, register, logout, updateProfile]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit être utilisé dans <AuthProvider>');
  return ctx;
};
