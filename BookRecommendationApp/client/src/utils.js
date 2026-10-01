export const SUGGESTED_GENRES = [
  'Roman',
  'Classique',
  'Littérature africaine',
  'Science-fiction',
  'Fantasy',
  'Policier',
  'Thriller',
  'Philosophie',
  'Histoire',
  'Essai',
  'Jeunesse',
  'Poésie',
  'Biographie',
  'Développement personnel',
];

export function timeAgo(date) {
  const diff = (Date.now() - new Date(date).getTime()) / 1000;
  if (diff < 60) return "à l'instant";
  const units = [
    [60 * 60 * 24 * 365, 'an', 'ans'],
    [60 * 60 * 24 * 30, 'mois', 'mois'],
    [60 * 60 * 24 * 7, 'semaine', 'semaines'],
    [60 * 60 * 24, 'jour', 'jours'],
    [60 * 60, 'heure', 'heures'],
    [60, 'minute', 'minutes'],
  ];
  for (const [secs, one, many] of units) {
    if (diff >= secs) {
      const n = Math.floor(diff / secs);
      return `il y a ${n} ${n > 1 ? many : one}`;
    }
  }
  return "à l'instant";
}

export function authorsLabel(authors) {
  return authors?.length ? authors.join(', ') : 'Auteur inconnu';
}

export function plural(n, one, many) {
  return `${n} ${n > 1 ? many : one}`;
}

export const REASON_LABELS = {
  following: 'Lecteur suivi',
  genre: 'Votre genre favori',
  popular: 'Populaire',
  discover: 'À découvrir',
};

/** Validation légère d'ISBN-10 / ISBN-13 (format + clé de contrôle). */
export function isValidIsbn(raw) {
  const s = String(raw || '').replace(/[\s-]/g, '').toUpperCase();
  if (/^\d{9}[\dX]$/.test(s)) {
    const sum = [...s].reduce((acc, c, i) => acc + (c === 'X' ? 10 : Number(c)) * (10 - i), 0);
    return sum % 11 === 0;
  }
  if (/^\d{13}$/.test(s)) {
    const sum = [...s.slice(0, 12)].reduce((acc, c, i) => acc + Number(c) * (i % 2 ? 3 : 1), 0);
    return (10 - (sum % 10)) % 10 === Number(s[12]);
  }
  return false;
}

/** Découpe une saisie « A, B ; C » en liste sans doublons. */
export function splitList(text) {
  const out = [];
  for (const part of String(text || '').split(/[,;]/)) {
    const s = part.trim().replace(/\s+/g, ' ');
    if (s && !out.some((x) => x.toLowerCase() === s.toLowerCase())) out.push(s);
  }
  return out;
}
