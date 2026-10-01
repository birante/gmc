import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, tokenStore } from '../utils/api.js';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(Boolean(tokenStore.get()));

  useEffect(() => {
    if (!tokenStore.get()) return;
    api('/auth/me')
      .then((d) => setUser(d.user))
      .catch(() => tokenStore.set(null))
      .finally(() => setLoading(false));
  }, []);

  const handleAuth = useCallback((data) => {
    tokenStore.set(data.token);
    setUser(data.user);
    return data.user;
  }, []);

  const login = useCallback((email, password) => api('/auth/login', { method: 'POST', body: { email, password } }).then(handleAuth), [handleAuth]);
  const register = useCallback((name, email, password) => api('/auth/register', { method: 'POST', body: { name, email, password } }).then(handleAuth), [handleAuth]);
  const logout = useCallback(() => {
    tokenStore.set(null);
    setUser(null);
  }, []);

  const value = useMemo(() => ({ user, loading, login, register, logout, isAdmin: user?.role === 'admin' }), [user, loading, login, register, logout]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
