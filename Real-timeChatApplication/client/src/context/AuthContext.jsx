import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, tokenStore } from '../api.js';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => tokenStore.get());
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(() => Boolean(tokenStore.get()));

  useEffect(() => {
    if (!token) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    api('/auth/me', { token })
      .then((data) => !cancelled && setUser(data.user))
      .catch(() => {
        if (cancelled) return;
        tokenStore.set(null);
        setToken(null);
        setUser(null);
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const applySession = useCallback((data) => {
    tokenStore.set(data.token);
    setToken(data.token);
    setUser(data.user);
  }, []);

  const login = useCallback(async (email, password) => {
    applySession(await api('/auth/login', { method: 'POST', body: { email, password }, token: null }));
  }, [applySession]);

  const register = useCallback(async (username, email, password) => {
    applySession(await api('/auth/register', { method: 'POST', body: { username, email, password }, token: null }));
  }, [applySession]);

  const logout = useCallback(() => {
    const t = tokenStore.get();
    if (t) api('/auth/logout', { method: 'POST', token: t }).catch(() => {});
    tokenStore.set(null);
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo(() => ({ token, user, loading, login, register, logout }), [token, user, loading, login, register, logout]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit être utilisé dans AuthProvider');
  return ctx;
}
