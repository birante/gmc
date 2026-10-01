import Avatar from './Avatar.jsx';

export default function OnlineUsers({ users, members = [], currentUserId }) {
  const onlineIds = new Set(users.map((u) => u.id));
  const offline = members.filter((m) => !onlineIds.has(m.id));
  return (
    <div className="online">
      <h3 className="side-title">En ligne — {users.length}</h3>
      <ul className="user-list">
        {users.map((u) => (
          <li key={u.id}>
            <Avatar user={u} size={30} online />
            <span>{u.username}{u.id === currentUserId && <span className="muted"> (vous)</span>}</span>
          </li>
        ))}
      </ul>
      {offline.length > 0 && (
        <>
          <h3 className="side-title">Hors ligne — {offline.length}</h3>
          <ul className="user-list offline">
            {offline.map((u) => (
              <li key={u.id}>
                <Avatar user={u} size={30} />
                <span>{u.username}</span>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
