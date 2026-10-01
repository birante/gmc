import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import { api, tokenStore } from '../api/client';
import type { User } from '../api/types';
import { AuthContext } from './auth-context';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(() => Boolean(tokenStore.get()));

  useEffect(() => {
    if (!tokenStore.get()) return;
    api
      .me()
      .then((r) => setUser(r.data))
      .catch(() => tokenStore.clear())
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const onLogout = () => setUser(null);
    window.addEventListener('vaxtrack:logout', onLogout);
    return () => window.removeEventListener('vaxtrack:logout', onLogout);
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const { data } = await api.login(email, password);
    tokenStore.set(data.token);
    setUser(data.user);
  }, []);

  const logout = useCallback(() => {
    tokenStore.clear();
    setUser(null);
  }, []);

  const value = useMemo(() => ({ user, loading, login, logout }), [user, loading, login, logout]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
