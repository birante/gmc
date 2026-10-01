import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client.js';
import FollowButton from '../components/FollowButton.jsx';
import { plural } from '../utils.js';

export default function ReadersPage() {
  const [q, setQ] = useState('');
  const [users, setUsers] = useState(null);

  useEffect(() => {
    const t = setTimeout(() => {
      api.users(q).then((d) => setUsers(d.users)).catch(() => setUsers([]));
    }, 250);
    return () => clearTimeout(t);
  }, [q]);

  return (
    <>
      <div className="page-head">
        <h1>Les lecteurs</h1>
        <p className="muted">Suivez des lecteurs pour voir leurs recommandations dans votre fil.</p>
      </div>
      <input className="search-input" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Rechercher un lecteur…" aria-label="Rechercher un lecteur" />
      {users === null && <div className="loader" aria-label="Chargement" />}
      {users?.length === 0 && <p className="empty">Aucun lecteur trouvé.</p>}
      <div className="reader-grid">
        {users?.map((u) => (
          <article key={u.id} className="reader-card">
            <Link to={`/lecteurs/${u.username}`} className="reader-card__head">
              <span className="avatar" aria-hidden="true">{u.username[0].toUpperCase()}</span>
              <span>
                <span className="strong">{u.username}</span>
                <span className="muted small block">{plural(u.followersCount, 'abonné', 'abonnés')}</span>
              </span>
            </Link>
            {u.bio && <p className="small clamp-3">{u.bio}</p>}
            {u.favoriteGenres?.length > 0 && <p className="tags">{u.favoriteGenres.slice(0, 3).map((g) => <span key={g} className="tag">{g}</span>)}</p>}
            <FollowButton userId={u.id} initialFollowing={u.isFollowing} small />
          </article>
        ))}
      </div>
    </>
  );
}
