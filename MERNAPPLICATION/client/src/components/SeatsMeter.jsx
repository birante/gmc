export default function SeatsMeter({ seatsLeft, capacity }) {
  const taken = capacity - seatsLeft;
  const pct = capacity > 0 ? Math.min(100, Math.round((taken / capacity) * 100)) : 0;
  const tone = pct >= 100 ? 'danger' : pct >= 80 ? 'warning' : 'success';
  return (
    <div className="meter">
      <div className="meter-labels">
        <span>
          <strong>{taken}</strong> / {capacity} inscrits
        </span>
        <span>{pct}%</span>
      </div>
      <div className="meter-track" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Taux de remplissage">
        <div className={`meter-fill meter-${tone}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
