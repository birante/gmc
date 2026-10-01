import { NEXT_STATUS, NEXT_STATUS_ACTION, PRIORITY_LABELS, STATUS_LABELS, formatDeadline, isOverdue } from '../utils/labels.js';

export default function TaskCard({ task, onStatusChange, onEdit, onDelete }) {
  const overdue = isOverdue(task);
  const deadline = formatDeadline(task.deadline);
  const next = NEXT_STATUS[task.status];
  return (
    <article className={`card task status-${task.status}${overdue ? ' overdue' : ''}`} data-testid="task-card">
      <div className="task-top">
        <button
          type="button"
          className={`check${task.status === 'done' ? ' checked' : ''}`}
          aria-label={task.status === 'done' ? `Marquer « ${task.title} » comme à faire` : `Marquer « ${task.title} » comme terminée`}
          onClick={() => onStatusChange(task, task.status === 'done' ? 'todo' : 'done')}
        >
          {task.status === 'done' ? '✓' : ''}
        </button>
        <div className="task-main">
          <h3 className="task-title">{task.title}</h3>
          {task.description && <p className="task-desc">{task.description}</p>}
        </div>
      </div>
      <div className="task-meta">
        <span className={`badge prio-${task.priority}`}>Priorité {PRIORITY_LABELS[task.priority].toLowerCase()}</span>
        <span className={`badge st-${task.status}`}>{STATUS_LABELS[task.status]}</span>
        {deadline && (
          <span className={`deadline${overdue ? ' is-overdue' : ''}`} title={new Date(task.deadline).toLocaleString('fr-FR')}>
            {overdue ? '⚠ En retard · ' : '📅 '}{deadline}
          </span>
        )}
      </div>
      <div className="task-actions">
        <button type="button" className="btn btn-soft btn-sm" onClick={() => onStatusChange(task, next)}>
          {NEXT_STATUS_ACTION[task.status]}
        </button>
        <button type="button" className="btn btn-ghost btn-sm" onClick={() => onEdit(task)} aria-label={`Modifier « ${task.title} »`}>Modifier</button>
        <button type="button" className="btn btn-danger-ghost btn-sm" onClick={() => onDelete(task)} aria-label={`Supprimer « ${task.title} »`}>Supprimer</button>
      </div>
    </article>
  );
}
