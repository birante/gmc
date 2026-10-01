import { Link } from 'react-router-dom';
import SeatsBadge from './SeatsBadge.jsx';
import EventImage from './EventImage.jsx';
import { CATEGORY_ICONS, dayOf, formatDateShort, monthOf } from '../utils/format.js';

export default function EventCard({ event }) {
  return (
    <article className={`event-card ${event.isPast ? 'is-past' : ''}`}>
      <Link to={`/events/${event.id}`} className="event-card-link" aria-label={`Voir ${event.title}`}>
        <div className="event-card-media">
          <EventImage src={event.imageUrl} alt={event.title} category={event.category} />
          <span className="chip chip-floating">
            {CATEGORY_ICONS[event.category]} {event.category}
          </span>
          <div className="date-tile" aria-hidden="true">
            <span className="date-day">{dayOf(event.date)}</span>
            <span className="date-month">{monthOf(event.date)}</span>
          </div>
        </div>
        <div className="event-card-body">
          <h3 className="event-card-title">{event.title}</h3>
          <p className="event-card-meta">
            <span aria-hidden="true">🕒</span> {formatDateShort(event.date)}
          </p>
          <p className="event-card-meta">
            <span aria-hidden="true">📍</span> {event.location}
          </p>
          <div className="event-card-footer">
            <SeatsBadge seatsLeft={event.seatsLeft} capacity={event.capacity} isPast={event.isPast} />
            {event.isRegistered && <span className="badge badge-primary">✓ Inscrit</span>}
            {event.isOrganizer && <span className="badge badge-outline">Organisateur</span>}
          </div>
          {event.organizer?.name && <p className="event-card-organizer">par {event.organizer.name}</p>}
        </div>
      </Link>
    </article>
  );
}
