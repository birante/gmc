import { useCallback, useEffect, useState } from 'react';
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api/client.js';
import BookCover from '../components/BookCover.jsx';
import RecommendationCard from '../components/RecommendationCard.jsx';
import StarRating from '../components/StarRating.jsx';
import { useAuth } from '../context/AuthContext.jsx';
import { authorsLabel, plural } from '../utils.js';

const REFRESH_MS = 15000;

export default function BookPage() {
  const { id } = useParams();
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [rating, setRating] = useState(false);
  const [flash, setFlash] = useState(location.state?.flash || '');
  const [expanded, setExpanded] = useState(false);

  const load = useCallback(
    () =>
      api
        .book(id)
        .then((d) => setData(d))
        .catch((e) => setError(e.message)),
    [id]
  );

  useEffect(() => {
    setData(null);
    load();
    // Rafraîchit la note moyenne pour refléter les votes des autres lecteurs
    const t = setInterval(() => {
      if (document.visibilityState === 'visible') api.book(id).then((d) => setData((prev) => (prev ? { ...prev, book: d.book } : d))).catch(() => {});
    }, REFRESH_MS);
    return () => clearInterval(t);
  }, [id, load]);

  async function rate(value) {
    if (!user) return navigate('/connexion', { state: { from: `/livres/${id}` } });
    setRating(true);
    try {
      const { book } = await api.rateBook(id, value);
      setData((d) => ({ ...d, book }));
      setFlash(`Merci ! Votre note de ${value}/5 a été enregistrée.`);
      setTimeout(() => setFlash(''), 3000);
    } catch (e) {
      setFlash(e.message);
    } finally {
      setRating(false);
    }
  }

  if (error) return <div className="empty empty--page"><p className="error">{error}</p><Link to="/recherche">Rechercher un livre</Link></div>;
  if (!data) return <div className="loader" aria-label="Chargement" />;
  const { book, recommendations } = data;
  const long = book.description?.length > 600;

  return (
    <>
      <section className="book-hero">
        <BookCover book={book} size="lg" />
        <div className="book-hero__info">
          {book.genres?.length > 0 && <p className="tags">{book.genres.map((g) => <span key={g} className="tag">{g}</span>)}</p>}
          <h1>{book.title}</h1>
          <p className="book-hero__authors">{authorsLabel(book.authors)}</p>
          <div className="rating-box" aria-live="polite">
            <span className="rating-box__value" data-testid="average">{book.ratingsCount ? book.averageRating.toFixed(1) : '–'}</span>
            <div>
              <StarRating value={book.averageRating} label="Note moyenne" />
              <p className="muted small">{book.ratingsCount ? `${plural(book.ratingsCount, 'vote', 'votes')} · moyenne des lecteurs` : 'Soyez le premier à noter ce livre'}</p>
            </div>
          </div>
          <div className="my-rating">
            <span className="small strong">{book.myRating ? 'Votre note (modifiable) :' : 'Votre note :'}</span>
            <StarRating value={book.myRating || 0} onRate={rate} disabled={rating} label="Noter ce livre" size="lg" />
          </div>
          {flash && <p className="notice small">{flash}</p>}
          <dl className="meta">
            {book.publishedDate && (<><dt>Publication</dt><dd>{book.publishedDate}</dd></>)}
            {book.pageCount && (<><dt>Pages</dt><dd>{book.pageCount}</dd></>)}
            {book.isbn && (<><dt>ISBN</dt><dd>{book.isbn}</dd></>)}
          </dl>
          <div className="row">
            <button className="btn btn--primary" onClick={() => navigate(user ? '/recommander' : '/connexion', { state: { book, from: `/livres/${id}` } })}>
              Recommander ce livre
            </button>
            {book.canEdit && (
              <Link to={`/livres/${book.id}/modifier`} className="btn btn--ghost">
                Modifier
              </Link>
            )}
          </div>
        </div>
      </section>
      <section className="panel">
        <h2 className="panel__title">Résumé</h2>
        {book.description ? (
          <>
            <p className={`description ${long && !expanded ? 'description--clamp' : ''}`}>{book.description}</p>
            {long && <button className="linklike" onClick={() => setExpanded((e) => !e)}>{expanded ? 'Réduire' : 'Lire la suite'}</button>}
          </>
        ) : (
          <p className="muted">Aucun résumé disponible.</p>
        )}
      </section>
      <section>
        <h2 className="section-title">Recommandations des lecteurs ({recommendations.length})</h2>
        {recommendations.length === 0 && <p className="empty">Personne n'a encore recommandé ce livre.</p>}
        <div className="stack">
          {recommendations.map((r) => (
            <RecommendationCard key={r.id} rec={r} showBook={false} onDelete={() => load()} />
          ))}
        </div>
      </section>
    </>
  );
}
