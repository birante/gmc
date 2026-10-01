import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../api.js';
import { useAuth } from '../context/AuthContext.jsx';
import { useSocket } from '../context/SocketContext.jsx';
import Avatar from '../components/Avatar.jsx';
import RoomList from '../components/RoomList.jsx';
import CreateRoomForm from '../components/CreateRoomForm.jsx';
import MessageList from '../components/MessageList.jsx';
import MessageInput from '../components/MessageInput.jsx';
import TypingIndicator from '../components/TypingIndicator.jsx';
import OnlineUsers from '../components/OnlineUsers.jsx';

const PAGE_SIZE = 30;
const TYPING_TTL = 5000;

export default function ChatPage() {
  const { roomId } = useParams();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const { socket, connected } = useSocket();

  const [rooms, setRooms] = useState([]);
  const [roomsLoaded, setRoomsLoaded] = useState(false);
  const [roomsError, setRoomsError] = useState('');
  const [messages, setMessages] = useState([]);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const [typers, setTypers] = useState({});
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [showUsers, setShowUsers] = useState(false);
  const [notice, setNotice] = useState('');
  const typingTimers = useRef({});

  const activeRoom = rooms.find((r) => r.id === roomId);
  const isMember = Boolean(activeRoom?.isMember);

  const withMembership = useCallback(
    (room) => ({ ...room, isMember: room.members.some((m) => m.id === user.id) }),
    [user.id],
  );

  const upsertRoom = useCallback(
    (room) =>
      setRooms((list) => {
        const r = withMembership(room);
        return list.some((x) => x.id === r.id) ? list.map((x) => (x.id === r.id ? r : x)) : [...list, r];
      }),
    [withMembership],
  );

  // Chargement des salons
  useEffect(() => {
    api('/rooms')
      .then((data) => setRooms(data.rooms))
      .catch((err) => setRoomsError(err.message))
      .finally(() => setRoomsLoaded(true));
  }, []);

  // Sélection par défaut
  useEffect(() => {
    if (!roomsLoaded || roomId || rooms.length === 0) return;
    const first = rooms.find((r) => r.isMember) || rooms[0];
    navigate(`/salons/${first.id}`, { replace: true });
  }, [roomsLoaded, roomId, rooms, navigate]);

  // Événements globaux : création de salon et mise à jour des membres
  useEffect(() => {
    if (!socket) return undefined;
    const onCreated = ({ room }) => upsertRoom(room);
    const onMembers = ({ room }) => upsertRoom(room);
    socket.on('room:created', onCreated);
    socket.on('room:members', onMembers);
    return () => {
      socket.off('room:created', onCreated);
      socket.off('room:members', onMembers);
    };
  }, [socket, upsertRoom]);

  // Historique du salon actif
  useEffect(() => {
    setMessages([]);
    setHasMore(false);
    setTypers({});
    setOnlineUsers([]);
    if (!roomId || !isMember) return undefined;
    let cancelled = false;
    setLoadingMessages(true);
    api(`/rooms/${roomId}/messages?limit=${PAGE_SIZE}`)
      .then((data) => {
        if (cancelled) return;
        setMessages(data.messages);
        setHasMore(data.hasMore);
      })
      .catch((err) => !cancelled && setNotice(err.message))
      .finally(() => !cancelled && setLoadingMessages(false));
    return () => {
      cancelled = true;
    };
  }, [roomId, isMember]);

  // Temps réel : rejoindre le salon côté socket
  useEffect(() => {
    if (!socket || !connected || !roomId || !isMember) return undefined;
    const onMessage = (msg) => {
      if (msg.room !== roomId) return;
      setMessages((list) => (list.some((m) => m.id === msg.id) ? list : [...list, msg]));
    };
    const onUsers = ({ roomId: rid, users }) => rid === roomId && setOnlineUsers(users);
    const onTyping = ({ roomId: rid, user: u, isTyping }) => {
      if (rid !== roomId || u.id === user.id) return;
      clearTimeout(typingTimers.current[u.id]);
      if (isTyping) {
        setTypers((t) => ({ ...t, [u.id]: u.username }));
        typingTimers.current[u.id] = setTimeout(
          () => setTypers(({ [u.id]: _gone, ...rest }) => rest),
          TYPING_TTL,
        );
      } else {
        setTypers(({ [u.id]: _gone, ...rest }) => rest);
      }
    };
    socket.on('message:new', onMessage);
    socket.on('room:users', onUsers);
    socket.on('typing', onTyping);
    socket.emit('room:join', { roomId }, (res) => {
      if (res?.users) setOnlineUsers(res.users);
      if (res?.error) setNotice(res.error);
    });
    const timers = typingTimers.current;
    return () => {
      socket.emit('room:leave', { roomId });
      socket.off('message:new', onMessage);
      socket.off('room:users', onUsers);
      socket.off('typing', onTyping);
      Object.values(timers).forEach(clearTimeout);
    };
  }, [socket, connected, roomId, isMember, user.id]);

  useEffect(() => {
    if (!notice) return undefined;
    const t = setTimeout(() => setNotice(''), 4000);
    return () => clearTimeout(t);
  }, [notice]);

  const loadOlder = async () => {
    if (!messages.length) return;
    setLoadingOlder(true);
    try {
      const before = encodeURIComponent(messages[0].createdAt);
      const data = await api(`/rooms/${roomId}/messages?limit=${PAGE_SIZE}&before=${before}`);
      setMessages((list) => [...data.messages.filter((m) => !list.some((x) => x.id === m.id)), ...list]);
      setHasMore(data.hasMore);
    } catch (err) {
      setNotice(err.message);
    } finally {
      setLoadingOlder(false);
    }
  };

  const sendMessage = (text) =>
    new Promise((resolve, reject) => {
      if (!socket || !connected) return reject(new Error('Connexion temps réel indisponible'));
      socket.timeout(8000).emit('message:send', { roomId, text }, (err, res) => {
        if (err) return reject(new Error("Le serveur n'a pas répondu"));
        if (res?.error) return reject(new Error(res.error));
        if (res?.message) setMessages((list) => (list.some((m) => m.id === res.message.id) ? list : [...list, res.message]));
        resolve();
      });
    });

  const sendTyping = (isTyping) => socket?.emit(isTyping ? 'typing:start' : 'typing:stop', { roomId });

  const createRoom = async (body) => {
    const { room } = await api('/rooms', { method: 'POST', body });
    upsertRoom(room);
    setShowCreate(false);
    selectRoom(room.id);
  };

  const joinRoom = async () => {
    try {
      const { room } = await api(`/rooms/${roomId}/join`, { method: 'POST' });
      upsertRoom(room);
    } catch (err) {
      setNotice(err.message);
    }
  };

  const leaveRoom = async () => {
    if (!window.confirm(`Quitter le salon « ${activeRoom.name} » ?`)) return;
    try {
      const { room } = await api(`/rooms/${roomId}/leave`, { method: 'POST' });
      upsertRoom(room);
      setShowUsers(false);
    } catch (err) {
      setNotice(err.message);
    }
  };

  function selectRoom(id) {
    navigate(`/salons/${id}`);
    setDrawerOpen(false);
  }

  const typingNames = Object.values(typers);

  return (
    <div className="chat-app">
      <aside className={`sidebar ${drawerOpen ? 'open' : ''}`} aria-label="Navigation">
        <div className="sidebar-head">
          <div className="brand"><span className="brand-logo">W</span> Waxtaan</div>
          <button type="button" className="icon-btn only-mobile" onClick={() => setDrawerOpen(false)} aria-label="Fermer le menu">✕</button>
        </div>
        <div className="sidebar-actions">
          <button type="button" className="btn btn-primary btn-block" onClick={() => setShowCreate((v) => !v)}>
            + Nouveau salon
          </button>
          {showCreate && <CreateRoomForm onCreate={createRoom} onCancel={() => setShowCreate(false)} />}
        </div>
        <div className="sidebar-rooms">
          {roomsError && <p className="form-error pad">{roomsError}</p>}
          {!roomsLoaded ? <p className="muted pad">Chargement…</p> : <RoomList rooms={rooms} activeId={roomId} onSelect={selectRoom} />}
        </div>
        <div className="me-card">
          <Avatar user={user} size={36} online={connected} />
          <div className="me-info">
            <strong>{user.username}</strong>
            <span className={`status ${connected ? 'on' : ''}`}>{connected ? 'En ligne' : 'Hors ligne'}</span>
          </div>
          <button type="button" className="btn btn-ghost btn-sm" onClick={logout}>Déconnexion</button>
        </div>
      </aside>
      {(drawerOpen || showUsers) && (
        <div className="backdrop" onClick={() => { setDrawerOpen(false); setShowUsers(false); }} aria-hidden="true" />
      )}

      <main className="conversation">
        <header className="conv-head">
          <button type="button" className="icon-btn only-mobile" onClick={() => setDrawerOpen(true)} aria-label="Ouvrir la liste des salons">☰</button>
          <div className="conv-title">
            {activeRoom ? (
              <>
                <h2># {activeRoom.name}</h2>
                <p className="muted">{activeRoom.description || `${activeRoom.memberCount} membre(s)`}</p>
              </>
            ) : (
              <h2>Waxtaan</h2>
            )}
          </div>
          {activeRoom && isMember && (
            <div className="conv-actions">
              <button type="button" className="btn btn-ghost btn-sm users-toggle" onClick={() => setShowUsers((v) => !v)} aria-label="Utilisateurs en ligne">
                <span className="dot-on" aria-hidden="true" /> {onlineUsers.length}
              </button>
              <button type="button" className="btn btn-ghost btn-sm" onClick={leaveRoom}>Quitter</button>
            </div>
          )}
        </header>

        {notice && <div className="toast" role="status">{notice}</div>}

        {!activeRoom ? (
          <div className="empty-state">
            <h3>Bienvenue {user.username} 👋</h3>
            <p className="muted">{roomsLoaded && rooms.length === 0 ? 'Créez le premier salon pour commencer.' : 'Choisissez un salon pour commencer à discuter.'}</p>
            <button type="button" className="btn btn-primary only-mobile" onClick={() => setDrawerOpen(true)}>Voir les salons</button>
          </div>
        ) : !isMember ? (
          <div className="empty-state">
            <h3># {activeRoom.name}</h3>
            {activeRoom.description && <p>{activeRoom.description}</p>}
            <p className="muted">{activeRoom.memberCount} membre(s). Rejoignez ce salon pour lire et envoyer des messages.</p>
            <button type="button" className="btn btn-primary" onClick={joinRoom}>Rejoindre le salon</button>
          </div>
        ) : (
          <>
            {loadingMessages ? (
              <div className="messages"><p className="muted pad">Chargement des messages…</p></div>
            ) : (
              <MessageList messages={messages} currentUserId={user.id} hasMore={hasMore} loadingOlder={loadingOlder} onLoadOlder={loadOlder} />
            )}
            <TypingIndicator names={typingNames} />
            <MessageInput key={roomId} onSend={sendMessage} onTyping={sendTyping} disabled={!connected} />
          </>
        )}
      </main>

      {activeRoom && isMember && (
        <aside className={`members-panel ${showUsers ? 'open' : ''}`} aria-label="Utilisateurs du salon">
          <div className="sidebar-head only-mobile">
            <strong>Membres</strong>
            <button type="button" className="icon-btn" onClick={() => setShowUsers(false)} aria-label="Fermer">✕</button>
          </div>
          <OnlineUsers users={onlineUsers} members={activeRoom.members} currentUserId={user.id} />
        </aside>
      )}
    </div>
  );
}
