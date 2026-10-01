import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import { useToast } from '../context/ToastContext.jsx';
import SeatsBadge from '../components/SeatsBadge.jsx';
import SeatsMeter from '../components/SeatsMeter.jsx';
import EventImage from '../components/EventImage.jsx';
import Spinner from '../components/Spinner.jsx';
import EmptyState from '../components/EmptyState.jsx';
import { CATEGORY_ICONS, formatDateLong, initials } from '../utils/format.js';

const REFRESH_MS = 10000;

export default function EventDetailPage() {
  const { id } = useParams();
  const { user } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const [event, setEvent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(
    (silent = false) =>
      api
        .getEvent(id)
        .then(({ event: e }) => {
          setEvent(e);
          setError('');
        })
        .catch((err) => !silent && setError(err.status === 404 ? 'notfound' : err.message))
        .finally(() => !silent && setLoading(false)),
    [id]
  );

  useEffect(() => {
    setLoading(true);
    load();
  }, [load, user]);

  // Places restantes « en direct » : rafraîchissement périodique
  useEffect(() => {
    const t = setInterval(() => document.visibilityState === 'visible' && load(true), REFRESH_MS);
    return () => clearInterval(t);
  }, [load]);

  const toggleRegistration = async () => {
    setBusy(true);
    try {
      const { event: e } = event.isRegistered ? await api.unregisterFromEvent(id) : await api.registerToEvent(id);
      setEvent((prev) => ({ ...prev, ...e, participants: prev.participants }));
      showToast(e.isRegistered ? 'Inscription confirmée 🎉' : 'Vous êtes désinscrit.', e.isRegistered ? 'success' : 'info');
    } catch (err) {
      showToast(err.message, 'error');
      load(true);
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Supprimer définitivement « ${event.title} » ?`)) return;
    try {
      await api.deleteEvent(id);
      showToast('Événement supprimé.', 'info');
      navigate('/dashboard');
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  if (loading) return <Spinner />;
  if (error === 'notfound') {
    return (
      <div className="container section">
        <EmptyState icon="🕳️" title="Événement introuvable">
          <p>Il a peut-être été supprimé par son organisateur.</p>
          <Link to="/" className="btn btn-primary">Voir les événements</Link>
        </EmptyState>
      </div>
    );
  }
  if (error) return <div className="container section"><div className="alert alert-error">{error}</div></div>;
  if (!event) return null;

  const full = event.seatsLeft <= 0;

  let action;
  if (event.isOrganizer) {
    action = (
      <div className="stack">
        <Link to={`/events/${id}/edit`} className="btn btn-primary btn-block">✏️ Modifier</Link>
        <button type="button" className="btn btn-danger btn-block" onClick={handleDelete}>🗑️ Supprimer</button>
      </div>
    );
  } else if (!user) {
    action = (
      <Link to="/login" state={{ from: `/events/${id}` }} className="btn btn-primary btn-block">
        Se connecter pour s'inscrire
      </Link>
    );
  } else if (event.isRegistered) {
    action = (
      <>
        <p className="registered-note">✓ Vous êtes inscrit à cet événement.</p>
        {!event.isPast && (
          <button type="button" className="btn btn-ghost btn-block" disabled={busy} onClick={toggleRegistration}>
            {busy ? '…' : 'Se désinscrire'}
          </button>
        )}
      </>
    );
  } else if (event.isPast) {
    action = <button type="button" className="btn btn-block" disabled>Événement terminé</button>;
  } else if (full) {
    action = <button type="button" className="btn btn-block" disabled>Complet</button>;
  } else {
    action = (
      <button type="button" className="btn btn-primary btn-block btn-lg" disabled={busy} onClick={toggleRegistration}>
        {busy ? 'Inscription…' : "S'inscrire"}
      </button>
    );
  }

  return (
    <article className="detail">
      <div className="detail-cover">
        <EventImage src={event.imageUrl} alt={event.title} category={event.category} />
      </div>
      <div className="container detail-layout">
        <div className="detail-main card">
          <div className="detail-tags">
            <span className="chip active">{CATEGORY_ICONS[event.category]} {event.category}</span>
            <SeatsBadge seatsLeft={event.seatsLeft} capacity={event.capacity} isPast={event.isPast} />
          </div>
          <h1 className="detail-title">{event.title}</h1>
          <ul className="detail-meta">
            <li><span aria-hidden="true">📅</span> {formatDateLong(event.date)}</li>
            <li><span aria-hidden="true">📍</span> {event.location}</li>
          </ul>
          <h2 className="section-title">À propos</h2>
          <p className="detail-description">{event.description}</p>

          {event.organizer && (
            <div className="organizer">
              <span className="avatar">{initials(event.organizer.name)}</span>
              <div>
                <p className="muted small">Organisé par</p>
                <p className="organizer-name">{event.organizer.name}</p>
                {event.organizer.bio && <p className="muted small">{event.organizer.bio}</p>}
              </div>
            </div>
          )}
        </div>

        <aside className="detail-side">
          <div className="card sticky">
            <h2 className="side-title">Places</h2>
            <p className="seats-big">
              <strong>{event.seatsLeft}</strong> place{event.seatsLeft > 1 ? 's' : ''} restante{event.seatsLeft > 1 ? 's' : ''}
            </p>
            <SeatsMeter seatsLeft={event.seatsLeft} capacity={event.capacity} />
            <p className="muted small live-dot">Mis à jour en direct</p>
            <div className="side-action">{action}</div>
          </div>

          {event.isOrganizer && (
            <div className="card">
              <h2 className="side-title">Participants ({event.participants?.length || 0})</h2>
              {event.participants?.length ? (
                <ul className="participants">
                  {event.participants.map((p) => (
                    <li key={p.id}>
                      <span className="avatar avatar-sm">{initials(p.name)}</span>
                      <div>
                        <p>{p.name}</p>
                        <p className="muted small">{p.email}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="muted">Aucun inscrit pour le moment.</p>
              )}
            </div>
          )}
        </aside>
      </div>
    </article>
  );
}
