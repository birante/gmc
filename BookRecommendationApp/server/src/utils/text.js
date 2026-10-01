/** Outils de normalisation de texte (recherche insensible à la casse et aux accents). */

export function stripAccents(s = '') {
  return String(s).normalize('NFD').replace(/[̀-ͯ]/g, '');
}

/** Clé de comparaison : minuscules, sans accents ni ponctuation, espaces réduits. */
export function normalizeKey(s = '') {
  return stripAccents(s)
    .toLowerCase()
    .replace(/[’'`]/g, ' ')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

export function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const ACCENT_CLASSES = {
  a: 'aàáâãäåā',
  c: 'cç',
  e: 'eèéêëē',
  i: 'iìíîïī',
  n: 'nñ',
  o: 'oòóôõöøō',
  u: 'uùúûüū',
  y: 'yýÿ',
};

/**
 * Construit une RegExp insensible à la casse ET aux accents :
 * « senghor », « Sédar » ou « eTRANGER » trouvent « Léopold Sédar Senghor » / « L'Étranger ».
 * Les apostrophes droites et typographiques sont équivalentes.
 */
export function accentInsensitiveRegex(query, { anchored = false } = {}) {
  const base = stripAccents(query.trim()).toLowerCase();
  let pattern = '';
  for (const ch of base) {
    if (ACCENT_CLASSES[ch]) pattern += `[${ACCENT_CLASSES[ch]}]`;
    else if (ch === "'" || ch === '’') pattern += "['’]";
    else if (/\s/.test(ch)) pattern += '\\s+';
    else pattern += escapeRegex(ch);
  }
  return new RegExp(anchored ? `^${pattern}$` : pattern, 'i');
}

/** Clé de déduplication titre + premier auteur. */
export function bookKey(title, authors = []) {
  return `${normalizeKey(title)}|${normalizeKey(authors?.[0] || '')}`;
}

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

export function cleanIsbn(raw) {
  return String(raw || '').replace(/[\s-]/g, '').toUpperCase();
}
