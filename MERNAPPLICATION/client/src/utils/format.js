export const CATEGORIES = ['Tech', 'Atelier', 'Conférence', 'Culture', 'Sport', 'Associatif', 'Autre'];

export const CATEGORY_ICONS = {
  Tech: '💻',
  Atelier: '🛠️',
  Conférence: '🎤',
  Culture: '🎭',
  Sport: '⚽',
  Associatif: '🤝',
  Autre: '✨',
};

const longFmt = new Intl.DateTimeFormat('fr-FR', {
  weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit',
});
const shortFmt = new Intl.DateTimeFormat('fr-FR', {
  day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
});

export const formatDateLong = (d) => longFmt.format(new Date(d));
export const formatDateShort = (d) => shortFmt.format(new Date(d));

export const dayOf = (d) => new Date(d).getDate();
export const monthOf = (d) =>
  new Intl.DateTimeFormat('fr-FR', { month: 'short' }).format(new Date(d)).replace('.', '');

/** Convertit une date en valeur pour <input type="datetime-local"> (heure locale). */
export const toLocalInput = (d) => {
  const date = new Date(d);
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

export const initials = (name = '') =>
  name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('') || '?';

export const plural = (n, word) => `${n} ${word}${Math.abs(n) > 1 ? 's' : ''}`;
