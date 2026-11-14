import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { api, getToken, setToken } from './api';
import type { User } from './types';

type AuthState = {
  status: 'unknown' | 'authenticated' | 'unauthenticated';
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthState['status']>('unknown');
  const [user, setUser] = useState<User | null>(null);

  const refresh = useCallback(async () => {
    const token = getToken();
    if (!token) {
      setUser(null);
      setStatus('unauthenticated');
      return;
    }
    try {
      const me = await api.me();
      setUser(me);
      setStatus('authenticated');
    } catch {
      setToken(null);
      setUser(null);
      setStatus('unauthenticated');
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const login = useCallback(async (email: string, password: string) => {
    const session = await api.login(email, password);
    setToken(session.token);
    setUser(session.user);
    setStatus('authenticated');
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.logout();
    } catch {
      /* ignore */
    }
    setToken(null);
    setUser(null);
    setStatus('unauthenticated');
  }, []);

  const value = useMemo(
    () => ({ status, user, login, logout, refresh }),
    [status, user, login, logout, refresh],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth outside provider');
  return ctx;
}
