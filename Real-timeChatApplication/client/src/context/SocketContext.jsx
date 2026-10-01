import { createContext, useContext, useEffect, useState } from 'react';
import { io } from 'socket.io-client';
import { useAuth } from './AuthContext.jsx';

const SocketContext = createContext({ socket: null, connected: false });

export function SocketProvider({ children }) {
  const { token, user, logout } = useAuth();
  const [socket, setSocket] = useState(null);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    if (!token || !user) return undefined;
    // Même origine, path par défaut /socket.io (fonctionne derrière kamal-proxy et le proxy Vite).
    const s = io({ auth: { token } });
    const onConnect = () => setConnected(true);
    const onDisconnect = () => setConnected(false);
    const onError = (err) => {
      setConnected(false);
      if (err?.message === 'Non authentifié') logout();
    };
    s.on('connect', onConnect);
    s.on('disconnect', onDisconnect);
    s.on('connect_error', onError);
    setSocket(s);
    return () => {
      // Déconnexion (logout ou changement de jeton) : on ferme le socket.
      s.off('connect', onConnect);
      s.off('disconnect', onDisconnect);
      s.off('connect_error', onError);
      s.disconnect();
      setSocket(null);
      setConnected(false);
    };
  }, [token, user?.id, logout]); // eslint-disable-line react-hooks/exhaustive-deps

  return <SocketContext.Provider value={{ socket, connected }}>{children}</SocketContext.Provider>;
}

export const useSocket = () => useContext(SocketContext);
