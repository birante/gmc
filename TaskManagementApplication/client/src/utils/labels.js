export const STATUS_LABELS = { todo: 'À faire', in_progress: 'En cours', done: 'Terminée' };
export const PRIORITY_LABELS = { low: 'Basse', medium: 'Moyenne', high: 'Haute' };
export const NEXT_STATUS = { todo: 'in_progress', in_progress: 'done', done: 'todo' };
export const NEXT_STATUS_ACTION = { todo: 'Démarrer', in_progress: 'Terminer', done: 'Rouvrir' };

export const SORT_OPTIONS = [
  { value: '-createdAt', label: 'Plus récentes' },
  { value: 'createdAt', label: 'Plus anciennes' },
  { value: 'deadline', label: 'Échéance la plus proche' },
  { value: '-deadline', label: 'Échéance la plus lointaine' },
  { value: '-priority', label: 'Priorité haute d’abord' },
  { value: 'priority', label: 'Priorité basse d’abord' },
];

export function isOverdue(task, now = Date.now()) {
  return Boolean(task.deadline && task.status !== 'done' && new Date(task.deadline).getTime() < now);
}

export function formatDeadline(deadline, now = new Date()) {
  if (!deadline) return null;
  const d = new Date(deadline);
  const startOf = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diffDays = Math.round((startOf(d) - startOf(now)) / 86400000);
  const date = d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: d.getFullYear() !== now.getFullYear() ? 'numeric' : undefined });
  if (diffDays === 0) return `Aujourd’hui · ${date}`;
  if (diffDays === 1) return `Demain · ${date}`;
  if (diffDays === -1) return `Hier · ${date}`;
  if (diffDays < 0) return `Il y a ${-diffDays} j · ${date}`;
  if (diffDays < 7) return `Dans ${diffDays} j · ${date}`;
  return date;
}

// Convertit une date ISO en valeur pour <input type="date"> (heure locale)
export function toDateInput(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

// Une échéance saisie « jour » est fixée à la fin de la journée locale
export function fromDateInput(value) {
  if (!value) return null;
  const [y, m, d] = value.split('-').map(Number);
  return new Date(y, m - 1, d, 23, 59, 0).toISOString();
}
