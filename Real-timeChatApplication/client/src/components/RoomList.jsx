export default function RoomList({ rooms, activeId, onSelect, unread = {} }) {
  if (rooms.length === 0) return <p className="muted pad">Aucun salon. Créez le premier !</p>;
  const mine = rooms.filter((r) => r.isMember);
  const others = rooms.filter((r) => !r.isMember);
  const renderRoom = (r) => (
    <li key={r.id}>
      <button
        type="button"
        className={`room-item ${r.id === activeId ? 'active' : ''}`}
        onClick={() => onSelect(r.id)}
        aria-current={r.id === activeId ? 'page' : undefined}
      >
        <span className="room-hash" aria-hidden="true">#</span>
        <span className="room-text">
          <span className="room-name">{r.name}</span>
          <span className="room-sub">{r.memberCount} membre{r.memberCount > 1 ? 's' : ''}</span>
        </span>
        {unread[r.id] > 0 && <span className="badge" aria-label={`${unread[r.id]} non lus`}>{unread[r.id]}</span>}
      </button>
    </li>
  );
  return (
    <nav aria-label="Salons">
      {mine.length > 0 && (
        <>
          <h3 className="side-title">Mes salons</h3>
          <ul className="room-list">{mine.map(renderRoom)}</ul>
        </>
      )}
      {others.length > 0 && (
        <>
          <h3 className="side-title">À découvrir</h3>
          <ul className="room-list">{others.map(renderRoom)}</ul>
        </>
      )}
    </nav>
  );
}
