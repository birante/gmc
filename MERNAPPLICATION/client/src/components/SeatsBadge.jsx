export function seatsStatus({ seatsLeft, capacity, isPast }) {
  if (isPast) return { label: 'Terminé', tone: 'muted' };
  if (seatsLeft <= 0) return { label: 'Complet', tone: 'danger' };
  const threshold = Math.max(3, Math.ceil(capacity * 0.1));
  const label = `${seatsLeft} place${seatsLeft > 1 ? 's' : ''} restante${seatsLeft > 1 ? 's' : ''}`;
  if (seatsLeft <= threshold) return { label: `Plus que ${seatsLeft} place${seatsLeft > 1 ? 's' : ''} !`, tone: 'warning' };
  return { label, tone: 'success' };
}

export default function SeatsBadge({ seatsLeft, capacity, isPast = false, className = '' }) {
  const { label, tone } = seatsStatus({ seatsLeft, capacity, isPast });
  return (
    <span className={`badge badge-${tone} ${className}`.trim()} data-testid="seats-badge">
      <span className="badge-dot" aria-hidden="true" />
      {label}
    </span>
  );
}
