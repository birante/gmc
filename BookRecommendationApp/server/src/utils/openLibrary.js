/**
 * Client Open Library (https://openlibrary.org) — API publique, sans clé.
 * Utilisé uniquement en complément du catalogue BookNest : tout échec est silencieux côté recherche.
 */
const BASE = 'https://openlibrary.org';
const COVERS = 'https://covers.openlibrary.org/b/id';
const TIMEOUT_MS = 5000;
const HEADERS = { 'User-Agent': 'BookNest/1.0 (booknest.okemamy.com)', Accept: 'application/json' };
const FIELDS = 'key,title,author_name,subject,first_publish_year,isbn,cover_i,number_of_pages_median';
const PARAM = { title: 'title', author: 'author', genre: 'subject' };

/** Format d'identifiant externe accepté : « ol:/works/OL45804W ». */
export const EXTERNAL_ID_RX = /^ol:\/works\/OL\d+W$/;

export function isExternalSearchEnabled() {
  return String(process.env.EXTERNAL_BOOK_SEARCH ?? 'true').toLowerCase() !== 'false';
}

export function coverUrl(coverId) {
  return coverId ? `${COVERS}/${coverId}-L.jpg` : '';
}

async function getJson(url) {
  const res = await fetch(url, { headers: HEADERS, signal: AbortSignal.timeout(TIMEOUT_MS) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Open Library a répondu ${res.status}`);
  return res.json();
}

function pickIsbn(list = []) {
  return list.find((i) => /^97[89]\d{10}$/.test(i)) || list.find((i) => /^\d{9}[\dX]$/i.test(i)) || '';
}

export function mapDoc(doc) {
  return {
    externalId: `ol:${doc.key}`,
    source: 'openlibrary',
    title: doc.title,
    authors: doc.author_name || [],
    genres: [...new Set((doc.subject || []).map((s) => String(s).trim()).filter((s) => s && s.length <= 40))].slice(0, 4),
    description: '',
    coverUrl: coverUrl(doc.cover_i),
    isbn: pickIsbn(doc.isbn),
    publishedDate: doc.first_publish_year ? String(doc.first_publish_year) : '',
    pageCount: doc.number_of_pages_median || undefined,
  };
}

export async function searchOpenLibrary(q, type = 'title', { limit = 20 } = {}) {
  const url = new URL(`${BASE}/search.json`);
  url.searchParams.set(PARAM[type] || 'title', q);
  url.searchParams.set('limit', String(limit));
  url.searchParams.set('fields', FIELDS);
  const data = await getJson(url);
  return (data?.docs || []).filter((d) => d?.key && d?.title).map(mapDoc);
}

function textValue(v) {
  if (!v) return '';
  return typeof v === 'string' ? v : v.value || '';
}

/** Récupère une œuvre Open Library par son externalId (+ noms des auteurs). null si introuvable. */
export async function getOpenLibraryWork(externalId) {
  if (!EXTERNAL_ID_RX.test(externalId)) return null;
  const key = externalId.slice(3);
  const work = await getJson(`${BASE}${key}.json`);
  if (!work?.title) return null;
  const authorKeys = (work.authors || []).map((a) => a?.author?.key).filter(Boolean).slice(0, 5);
  const authors = (
    await Promise.all(
      authorKeys.map((k) =>
        getJson(`${BASE}${k}.json`)
          .then((a) => a?.name || '')
          .catch(() => '')
      )
    )
  ).filter(Boolean);
  const year = String(work.first_publish_date || '').match(/\d{4}/)?.[0] || '';
  return {
    externalId,
    source: 'openlibrary',
    title: work.title,
    authors,
    genres: (work.subjects || []).filter((s) => typeof s === 'string' && s.length <= 40).slice(0, 4),
    description: textValue(work.description).slice(0, 5000),
    coverUrl: coverUrl(work.covers?.find((c) => c > 0)),
    isbn: '',
    publishedDate: year,
  };
}
