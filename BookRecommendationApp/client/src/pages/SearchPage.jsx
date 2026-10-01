import { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { api } from '../api/client.js';
import BookTile from '../components/BookTile.jsx';
import { useAuth } from '../context/AuthContext.jsx';
import { plural } from '../utils.js';

const TYPES = [
  { value: 'title', label: 'Titre' },
  { value: 'author', label: 'Auteur' },
  { value: 'genre', label: 'Genre' },
];

const EMPTY = { loading: false, results: null, localCount: 0, externalCount: 0, externalEnabled: true, externalAvailable: true, error: '' };

/** Champs transmis pour importer un résultat Open Library dans le catalogue. */
export function importPayload(b) {
  const { externalId, title, authors, genres, description, coverUrl, isbn, publishedDate, pageCount } = b;
  return { externalId, title, authors, genres, description, coverUrl, isbn, publishedDate, pageCount };
}

export default function SearchPage() {
  const [params, setParams] = useSearchParams();
  const { user } = useAuth();
  const navigate = useNavigate();
  const q = params.get('q') || '';
  const type = params.get('type') || 'title';
  const [input, setInput] = useState(q);
  const [state, setState] = useState(EMPTY);
  const [importing, setImporting] = useState('');

  useEffect(() => setInput(q), [q]);

  useEffect(() => {
    if (!q) return;
    let alive = true;
    setState((s) => ({ ...s, loading: true, error: '' }));
    api
      .searchBooks(q, type)
      .then((d) => alive && setState({ ...EMPTY, ...d, loading: false }))
      .catch((e) => alive && setState({ ...EMPTY, results: [], error: e.message }));
    return () => {
      alive = false;
    };
  }, [q, type]);

  function submit(e) {
    e.preventDefault();
    if (input.trim()) setParams({ q: input.trim(), type });
  }

  const requireLogin = () => navigate('/connexion', { state: { from: `/recherche?${params}` } });

  async function importAndOpen(b) {
    if (!user) return requireLogin();
    setImporting(b.externalId);
    try {
      const { book } = await api.createBook(importPayload(b));
      navigate(`/livres/${book.id}`);
    } catch (e) {
      setState((s) => ({ ...s, error: e.message }));
    } finally {
      setImporting('');
    }
  }

  const addLink = { pathname: '/livres/nouveau', search: q ? `?${new URLSearchParams(type === 'author' ? { auteur: q } : type === 'genre' ? { genre: q } : { titre: q })}` : '' };
  const results = state.results || [];

  return (
    <>
      <div className="page-head">
        <h1>Rechercher un livre</h1>
        <p className="muted">Cherchez dans le catalogue BookNest par titre, auteur ou genre. Les résultats d'Open Library complètent la recherche.</p>
      </div>
      <form className="searchbar" onSubmit={submit} role="search">
        <div className="segmented" role="radiogroup" aria-label="Type de recherche">
          {TYPES.map((t) => (
            <button
              type="button"
              key={t.value}
              role="radio"
              aria-checked={type === t.value}
              className={type === t.value ? 'on' : ''}
              onClick={() => setParams(q ? { q, type: t.value } : { type: t.value })}
            >
              {t.label}
            </button>
          ))}
        </div>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder={type === 'author' ? 'Ex. Mohamed Mbougar Sarr' : type === 'genre' ? 'Ex. Poésie, Science-fiction' : 'Ex. Le Petit Prince'}
          aria-label="Recherche"
        />
        <button className="btn btn--primary">Rechercher</button>
      </form>
      {q && !state.loading && state.results && state.externalEnabled && !state.externalAvailable && (
        <p className="notice">Open Library est momentanément injoignable : seuls les résultats du catalogue BookNest sont affichés.</p>
      )}
      {state.error && <p className="error">{state.error}</p>}
      {state.loading && <div className="loader" aria-label="Recherche en cours" />}
      {!state.loading && state.results && results.length === 0 && !state.error && (
        <div className="empty">
          <p>Aucun résultat pour « {q} ».</p>
          <p className="small muted">Ce livre n'est pas encore dans le catalogue ? Ajoutez-le pour la communauté.</p>
          <Link to={addLink} className="btn btn--primary btn--sm">Ajouter ce livre</Link>
        </div>
      )}
      {!state.loading && results.length > 0 && (
        <>
          <p className="muted small">
            {plural(state.localCount, 'résultat', 'résultats')} dans le catalogue BookNest
            {state.externalCount > 0 && ` · ${plural(state.externalCount, 'résultat', 'résultats')} via Open Library`}
          </p>
          <div className="book-grid">
            {results.map((b) => (
              <BookTile
                key={b.id || b.externalId}
                book={b}
                actions={
                  <div className="tile-actions">
                    {!b.id && (
                      <button className="btn btn--ghost btn--sm" disabled={importing === b.externalId} onClick={() => importAndOpen(b)}>
                        {importing === b.externalId ? 'Ajout…' : 'Ajouter au catalogue'}
                      </button>
                    )}
                    <button className="btn btn--ghost btn--sm" onClick={() => (user ? navigate('/recommander', { state: { book: b } }) : requireLogin())}>
                      Recommander
                    </button>
                  </div>
                }
              />
            ))}
          </div>
          <p className="small muted search-foot">
            Vous ne trouvez pas votre livre ? <Link to={addLink}>Ajoutez-le au catalogue</Link>.
          </p>
        </>
      )}
      {!q && (
        <div className="suggestions">
          <p className="muted">Quelques idées :</p>
          <div className="chips">
            {[
              ['Senghor', 'author'],
              ['La plus secrète mémoire des hommes', 'title'],
              ['Littérature africaine', 'genre'],
              ['Science-fiction', 'genre'],
              ['Albert Camus', 'author'],
              ['Programmation', 'genre'],
            ].map(([s, t]) => (
              <button key={s} className="chip" onClick={() => setParams({ q: s, type: t })}>
                {s}
              </button>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
