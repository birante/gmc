import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { api } from '../api/client.js';
import BookCover from '../components/BookCover.jsx';
import StarRating from '../components/StarRating.jsx';
import { authorsLabel } from '../utils.js';

const EMPTY = { title: '', authors: '', description: '', genres: '', coverUrl: '', isbn: '' };

export default function RecommendPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const [picked, setPicked] = useState(location.state?.book || null);
  const [manual, setManual] = useState(EMPTY);
  const [rating, setRating] = useState(0);
  const [review, setReview] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const [q, setQ] = useState('');
  const [results, setResults] = useState(null);
  const [searching, setSearching] = useState(false);

  async function search(e) {
    e.preventDefault();
    if (!q.trim()) return;
    setSearching(true);
    try {
      const d = await api.searchBooks(q.trim(), 'title');
      setResults(d.results.slice(0, 8));
    } catch (err) {
      setError(err.message);
    } finally {
      setSearching(false);
    }
  }

  const setM = (k) => (e) => setManual({ ...manual, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault();
    setError('');
    if (!rating) return setError('Choisissez une note de 1 à 5 étoiles.');
    let payload;
    if (picked?.id) payload = { bookId: picked.id };
    else if (picked?.externalId) {
      const { externalId, title, authors, genres, description, coverUrl, isbn, publishedDate, pageCount } = picked;
      payload = { book: { externalId, title, authors, genres, description, coverUrl, isbn, publishedDate, pageCount } };
    } else {
      if (!manual.title.trim()) return setError('Le titre du livre est requis.');
      payload = {
        book: {
          ...manual,
          authors: manual.authors.split(',').map((s) => s.trim()).filter(Boolean),
          genres: manual.genres.split(',').map((s) => s.trim()).filter(Boolean),
        },
      };
    }
    setBusy(true);
    try {
      const { recommendation } = await api.createRecommendation({ ...payload, rating, review });
      navigate(`/livres/${recommendation.book.id}`);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="narrow">
      <div className="page-head">
        <h1>Recommander un livre</h1>
        <p className="muted">Partagez un coup de cœur avec la communauté : choisissez un livre, notez-le et dites pourquoi il vaut le détour.</p>
      </div>

      <form className="form panel" onSubmit={submit}>
        <h2 className="panel__title">1. Le livre</h2>
        {picked ? (
          <div className="picked">
            <BookCover book={picked} size="sm" />
            <div>
              <p className="strong">{picked.title}</p>
              <p className="muted small">{authorsLabel(picked.authors)}</p>
              {picked.description && <p className="small clamp-3">{picked.description}</p>}
              <button type="button" className="linklike" onClick={() => setPicked(null)}>Choisir un autre livre</button>
            </div>
          </div>
        ) : (
          <>
            <div className="inline-search">
              <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Chercher dans le catalogue…" aria-label="Chercher un livre" onKeyDown={(e) => e.key === 'Enter' && search(e)} />
              <button type="button" className="btn btn--ghost" onClick={search} disabled={searching}>{searching ? '…' : 'Chercher'}</button>
            </div>
            {results && (
              <ul className="pick-list">
                {results.length === 0 && <li className="muted small">Aucun résultat, saisissez le livre ci-dessous.</li>}
                {results.map((b) => (
                  <li key={b.id || b.externalId}>
                    <button type="button" onClick={() => setPicked(b)}>
                      <BookCover book={b} size="xs" />
                      <span>
                        <span className="strong">{b.title}</span>
                        <span className="muted small"> — {authorsLabel(b.authors)}{!b.id && b.source === 'openlibrary' ? ' · Open Library' : ''}</span>
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
            <p className="divider"><span>ou saisissez-le à la main</span></p>
            <div className="form-row">
              <label>
                Titre *
                <input value={manual.title} onChange={setM('title')} maxLength={300} />
              </label>
              <label>
                Auteur(s) <span className="muted small">(séparés par des virgules)</span>
                <input value={manual.authors} onChange={setM('authors')} />
              </label>
            </div>
            <label>
              Description
              <textarea rows={3} value={manual.description} onChange={setM('description')} />
            </label>
            <div className="form-row">
              <label>
                Genres <span className="muted small">(virgules)</span>
                <input value={manual.genres} onChange={setM('genres')} placeholder="Roman, Classique" />
              </label>
              <label>
                ISBN
                <input value={manual.isbn} onChange={setM('isbn')} />
              </label>
            </div>
          </>
        )}

        <h2 className="panel__title">2. Votre avis</h2>
        <div className="field">
          <span className="label">Votre note *</span>
          <StarRating value={rating} onRate={setRating} size="lg" label="Votre note" />
        </div>
        <label>
          Pourquoi le recommandez-vous ? *
          <textarea rows={5} value={review} onChange={(e) => setReview(e.target.value)} required minLength={3} maxLength={2000} placeholder="Ce qui vous a touché, à qui vous le conseillez…" />
        </label>
        {error && <p className="error" role="alert">{error}</p>}
        <button className="btn btn--primary btn--block" disabled={busy}>{busy ? 'Publication…' : 'Publier ma recommandation'}</button>
      </form>
    </div>
  );
}
