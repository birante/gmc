import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client.js';
import RecommendationCard from '../components/RecommendationCard.jsx';
import { useAuth } from '../context/AuthContext.jsx';

function Feed() {
  const { user } = useAuth();
  const [items, setItems] = useState(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .feed(page)
      .then((d) => {
        setItems((prev) => (page === 1 ? d.recommendations : [...(prev || []), ...d.recommendations]));
        setHasMore(d.hasMore);
      })
      .catch((e) => setError(e.message));
  }, [page]);

  return (
    <div className="feed-layout">
      <section>
        <div className="page-head">
          <h1>Bonjour {user.username} 📖</h1>
          <p className="muted">Votre fil : les lecteurs que vous suivez, vos genres préférés et les coups de cœur du moment.</p>
        </div>
        {error && <p className="error">{error}</p>}
        {items === null && !error && <div className="loader" aria-label="Chargement" />}
        {items?.length === 0 && (
          <div className="empty">
            <p>Votre fil est encore vide.</p>
            <p>
              <Link to="/lecteurs">Suivez des lecteurs</Link> ou <Link to="/recommander">recommandez votre premier livre</Link>.
            </p>
          </div>
        )}
        <div className="stack">
          {items?.map((rec) => (
            <RecommendationCard key={rec.id} rec={rec} onDelete={(id) => setItems((xs) => xs.filter((x) => x.id !== id))} />
          ))}
        </div>
        {hasMore && (
          <button className="btn btn--ghost btn--block" onClick={() => setPage((p) => p + 1)}>
            Voir plus
          </button>
        )}
      </section>
      <aside className="sidebar">
        <div className="panel">
          <h2 className="panel__title">Vos genres</h2>
          {user.favoriteGenres?.length ? (
            <p className="tags">{user.favoriteGenres.map((g) => <span key={g} className="tag">{g}</span>)}</p>
          ) : (
            <p className="muted small">Ajoutez des genres favoris depuis votre profil pour personnaliser le fil.</p>
          )}
          <Link to={`/lecteurs/${user.username}`} className="small">Modifier mon profil →</Link>
        </div>
        <div className="panel panel--accent">
          <h2 className="panel__title">Un livre à partager ?</h2>
          <p className="small">Cherchez-le dans le catalogue, ou ajoutez-le vous-même s’il n’y est pas encore.</p>
          <div className="row"><Link to="/recommander" className="btn btn--primary btn--sm">Recommander un livre</Link><Link to="/livres/nouveau" className="btn btn--ghost btn--sm">Ajouter un livre</Link></div>
        </div>
      </aside>
    </div>
  );
}

function Landing() {
  const [recs, setRecs] = useState([]);
  useEffect(() => {
    api.recommendations({ limit: 6 }).then((d) => setRecs(d.recommendations)).catch(() => {});
  }, []);
  return (
    <>
      <section className="hero">
        <div className="hero__text">
          <p className="eyebrow">Le réseau social des lecteurs</p>
          <h1>Trouvez votre prochain livre grâce à de vrais lecteurs.</h1>
          <p className="lead">
            Fini les listes de best-sellers génériques. Sur BookNest, suivez des lecteurs qui vous ressemblent, notez vos lectures et partagez vos coups de cœur.
          </p>
          <div className="hero__cta">
            <Link to="/inscription" className="btn btn--primary">Créer mon compte</Link>
            <Link to="/recherche" className="btn btn--ghost">Explorer les livres</Link>
          </div>
        </div>
        <div className="hero__shelf" aria-hidden="true">
          {['#7a2e2e', '#2f4a3a', '#c08a3e', '#3a4560', '#5b3a29', '#8a5a44', '#4d2d4f'].map((c, i) => (
            <span key={c} className="spine" style={{ '--c': c, '--h': `${70 + ((i * 13) % 30)}%` }} />
          ))}
        </div>
      </section>
      <section className="features">
        <div className="feature"><span className="feature__icon">🔎</span><h3>Recherchez</h3><p>Par titre, auteur ou genre dans le catalogue BookNest, complété par Open Library.</p></div>
        <div className="feature"><span className="feature__icon">⭐</span><h3>Notez</h3><p>Votez de 1 à 5 étoiles, la moyenne se met à jour en direct.</p></div>
        <div className="feature"><span className="feature__icon">💬</span><h3>Échangez</h3><p>Aimez, commentez et suivez d'autres lecteurs.</p></div>
      </section>
      {recs.length > 0 && (
        <section>
          <h2 className="section-title">Les dernières recommandations</h2>
          <div className="stack">
            {recs.map((r) => <RecommendationCard key={r.id} rec={r} />)}
          </div>
        </section>
      )}
    </>
  );
}

export default function HomePage() {
  const { user, loading } = useAuth();
  if (loading) return <div className="loader" aria-label="Chargement" />;
  return user ? <Feed /> : <Landing />;
}
