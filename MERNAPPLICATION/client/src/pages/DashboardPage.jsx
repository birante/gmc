import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import { useToast } from '../context/ToastContext.jsx';
import Spinner from '../components/Spinner.jsx';
import EmptyState from '../components/EmptyState.jsx';
import SeatsBadge from '../components/SeatsBadge.jsx';
import EventImage from '../components/EventImage.jsx';
import { formatDateShort } from '../utils/format.js';

function EventRow({ event, children }) {
  return (
    <li className="row-card">
      <Link to={`/events/${event.id}`} className="row-thumb">
        <EventImage src={event.imageUrl} alt={event.title} category={event.category} />
      </Link>
      <div className="row-info">
        <Link to={`/events/${event.id}`} className="row-title">{event.title}</Link>
        <p className="muted small">
          📅 {formatDateShort(event.date)} · 📍 {event.location} · {event.category}
        </p>
        <div className="row-badges">
          <SeatsBadge seatsLeft={event.seatsLeft} capacity={event.capacity} isPast={event.isPast} />
          <span className="badge badge-outline">{event.attendeesCount} / {event.capacity} inscrits</span>
        </div>
      </div>
      <div className="row-actions">{children}</div>
    </li>
  );
}

export default function DashboardPage() {
  const { user } = useAuth();
  const { showToast } = useToast();
  const [params, setParams] = useSearchParams();
  const tab = params.get('tab') === 'registrations' ? 'registrations' : 'created';
  const [created, setCreated] = useState([]);
  const [registrations, setRegistrations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([api.myEvents(), api.myRegistrations()])
      .then(([c, r]) => {
        setCreated(c.events);
        setRegistrations(r.events);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  const handleDelete = async (event) => {
    if (!window.confirm(`Supprimer « ${event.title} » ?`)) return;
    try {
      await api.deleteEvent(event.id);
      setCreated((list) => list.filter((e) => e.id !== event.id));
      showToast('Événement supprimé.', 'info');
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const handleUnregister = async (event) => {
    try {
      await api.unregisterFromEvent(event.id);
      setRegistrations((list) => list.filter((e) => e.id !== event.id));
      showToast('Désinscription effectuée.', 'info');
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const upcomingRegs = registrations.filter((e) => !e.isPast).length;
  const totalAttendees = created.reduce((sum, e) => sum + e.attendeesCount, 0);
  const stats = [
    { label: 'Événements créés', value: created.length, icon: '📣' },
    { label: 'Participants cumulés', value: totalAttendees, icon: '👥' },
    { label: 'Mes inscriptions', value: registrations.length, icon: '🎟️' },
    { label: 'Inscriptions à venir', value: upcomingRegs, icon: '⏳' },
  ];

  const list = tab === 'created' ? created : registrations;

  return (
    <section className="container section">
      <div className="page-head">
        <div>
          <p className="eyebrow dark">Tableau de bord</p>
          <h1 className="page-title">Bonjour, {user.name.split(' ')[0]} 👋</h1>
        </div>
        <Link to="/events/new" className="btn btn-primary">+ Créer un événement</Link>
      </div>

      {error && <div className="alert alert-error">{error}</div>}
      {loading ? (
        <Spinner />
      ) : (
        <>
          <div className="stats">
            {stats.map((s) => (
              <div key={s.label} className="stat card">
                <span className="stat-icon" aria-hidden="true">{s.icon}</span>
                <div>
                  <p className="stat-value">{s.value}</p>
                  <p className="stat-label">{s.label}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="tabs" role="tablist">
            <button
              type="button"
              role="tab"
              aria-selected={tab === 'created'}
              className={tab === 'created' ? 'active' : ''}
              onClick={() => setParams({})}
            >
              Mes événements créés <span className="count">{created.length}</span>
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={tab === 'registrations'}
              className={tab === 'registrations' ? 'active' : ''}
              onClick={() => setParams({ tab: 'registrations' })}
            >
              Mes inscriptions <span className="count">{registrations.length}</span>
            </button>
          </div>

          {list.length === 0 ? (
            tab === 'created' ? (
              <EmptyState icon="📣" title="Vous n'avez encore créé aucun événement">
                <Link to="/events/new" className="btn btn-primary">Créer mon premier événement</Link>
              </EmptyState>
            ) : (
              <EmptyState icon="🎟️" title="Aucune inscription pour le moment">
                <Link to="/" className="btn btn-primary">Découvrir les événements</Link>
              </EmptyState>
            )
          ) : (
            <ul className="row-list">
              {list.map((e) => (
                <EventRow key={e.id} event={e}>
                  {tab === 'created' ? (
                    <>
                      <Link to={`/events/${e.id}/edit`} className="btn btn-ghost btn-sm">Modifier</Link>
                      <button type="button" className="btn btn-danger-ghost btn-sm" onClick={() => handleDelete(e)}>
                        Supprimer
                      </button>
                    </>
                  ) : (
                    !e.isPast && (
                      <button type="button" className="btn btn-ghost btn-sm" onClick={() => handleUnregister(e)}>
                        Se désinscrire
                      </button>
                    )
                  )}
                </EventRow>
              ))}
            </ul>
          )}
        </>
      )}
    </section>
  );
}
