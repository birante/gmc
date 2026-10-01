export default function StatsPanel({ stats }) {
  const s = stats || { total: 0, byStatus: { todo: 0, in_progress: 0, done: 0 }, overdue: 0, completionRate: 0 };
  return (
    <section className="stats" aria-label="Indicateurs">
      <div className="card progress-card">
        <div className="progress-head">
          <h2>Progression</h2>
          <strong className="progress-value">{s.completionRate}%</strong>
        </div>
        <div className="progress" role="progressbar" aria-label="Part des tâches terminées" aria-valuemin={0} aria-valuemax={100} aria-valuenow={s.completionRate}>
          <div className="progress-bar" style={{ width: `${s.completionRate}%` }} />
        </div>
        <p className="muted">{s.byStatus.done} tâche{s.byStatus.done > 1 ? 's' : ''} terminée{s.byStatus.done > 1 ? 's' : ''} sur {s.total}</p>
      </div>
      <div className="counters">
        <div className="card counter"><span className="counter-value">{s.total}</span><span className="counter-label">Total</span></div>
        <div className="card counter c-todo"><span className="counter-value">{s.byStatus.todo}</span><span className="counter-label">À faire</span></div>
        <div className="card counter c-progress"><span className="counter-value">{s.byStatus.in_progress}</span><span className="counter-label">En cours</span></div>
        <div className="card counter c-done"><span className="counter-value">{s.byStatus.done}</span><span className="counter-label">Terminées</span></div>
        <div className={`card counter c-overdue${s.overdue ? ' is-alert' : ''}`}><span className="counter-value">{s.overdue}</span><span className="counter-label">En retard</span></div>
      </div>
    </section>
  );
}
