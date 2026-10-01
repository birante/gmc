import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import EventCard from '../components/EventCard.jsx';
import Pagination from '../components/Pagination.jsx';
import Spinner from '../components/Spinner.jsx';
import EmptyState from '../components/EmptyState.jsx';
import { CATEGORIES, CATEGORY_ICONS } from '../utils/format.js';

const WHEN_OPTIONS = [
  { value: 'upcoming', label: 'À venir' },
  { value: 'past', label: 'Passés' },
  { value: 'all', label: 'Tous' },
];

export default function EventsPage() {
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const search = params.get('search') || '';
  const category = params.get('category') || '';
  const when = params.get('when') || 'upcoming';
  const page = Number(params.get('page')) || 1;

  const [searchInput, setSearchInput] = useState(search);
  const [data, setData] = useState({ events: [], total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const update = (changes) => {
    const next = new URLSearchParams(params);
    Object.entries(changes).forEach(([k, v]) => (v ? next.set(k, v) : next.delete(k)));
    if (!('page' in changes)) next.delete('page');
    setParams(next);
  };

  // Recherche avec anti-rebond
  useEffect(() => {
    if (searchInput === search) return undefined;
    const t = setTimeout(() => update({ search: searchInput.trim() }), 350);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchInput]);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError('');
    api
      .listEvents({ search, category, when: when === 'all' ? '' : when, page }, controller.signal)
      .then(setData)
      .catch((err) => err.name !== 'AbortError' && setError(err.message))
      .finally(() => !controller.signal.aborted && setLoading(false));
    return () => controller.abort();
    // `user` : rafraîchit les badges « Inscrit » après connexion/déconnexion
  }, [search, category, when, page, user]);

  const resetFilters = () => {
    setSearchInput('');
    setParams(new URLSearchParams());
  };

  return (
    <>
      <section className="hero">
        <div className="container hero-inner">
          <div>
            <p className="eyebrow">Meetups · Ateliers · Conférences · Soirées associatives</p>
            <h1>
              Créez, publiez et rejoignez des <span className="gradient-text">événements</span> en quelques clics.
            </h1>
            <p className="hero-lead">
              Fini les inscriptions par WhatsApp et les tableurs : EventHub centralise la publication,
              les inscriptions et le suivi des places en temps réel.
            </p>
            <div className="hero-actions">
              <Link to={user ? '/events/new' : '/register'} className="btn btn-light btn-lg">
                {user ? '+ Créer un événement' : 'Commencer gratuitement'}
              </Link>
              {user && (
                <Link to="/dashboard" className="btn btn-outline-light btn-lg">Mon tableau de bord</Link>
              )}
            </div>
          </div>
        </div>
      </section>

      <section className="container section">
        <div className="filters card">
          <div className="search-field">
            <span aria-hidden="true">🔍</span>
            <input
              type="search"
              placeholder="Rechercher un événement, un lieu…"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              aria-label="Rechercher"
            />
          </div>
          <div className="segmented" role="tablist" aria-label="Période">
            {WHEN_OPTIONS.map((o) => (
              <button
                key={o.value}
                type="button"
                role="tab"
                aria-selected={when === o.value}
                className={when === o.value ? 'active' : ''}
                onClick={() => update({ when: o.value === 'upcoming' ? '' : o.value })}
              >
                {o.label}
              </button>
            ))}
          </div>
          <div className="chips" role="group" aria-label="Catégories">
            <button type="button" className={`chip ${!category ? 'active' : ''}`} onClick={() => update({ category: '' })}>
              Toutes
            </button>
            {CATEGORIES.map((c) => (
              <button
                key={c}
                type="button"
                className={`chip ${category === c ? 'active' : ''}`}
                onClick={() => update({ category: category === c ? '' : c })}
              >
                {CATEGORY_ICONS[c]} {c}
              </button>
            ))}
          </div>
        </div>

        <div className="results-header">
          <h2>
            {when === 'past' ? 'Événements passés' : when === 'all' ? 'Tous les événements' : 'Événements à venir'}
          </h2>
          {!loading && <span className="muted">{data.total} résultat{data.total > 1 ? 's' : ''}</span>}
        </div>

        {error && <div className="alert alert-error">{error}</div>}
        {loading ? (
          <Spinner />
        ) : data.events.length === 0 ? (
          <EmptyState icon="🔎" title="Aucun événement trouvé">
            <p>Essayez d'autres mots-clés ou filtres.</p>
            <button type="button" className="btn btn-ghost" onClick={resetFilters}>Réinitialiser les filtres</button>
          </EmptyState>
        ) : (
          <>
            <div className="event-grid">
              {data.events.map((e) => (
                <EventCard key={e.id} event={e} />
              ))}
            </div>
            <Pagination page={data.page || page} totalPages={data.totalPages} onChange={(p) => update({ page: String(p) })} />
          </>
        )}
      </section>
    </>
  );
}
