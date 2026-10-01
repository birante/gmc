import Book from '../models/Book.js';
import Recommendation from '../models/Recommendation.js';
import { HttpError } from '../utils/httpError.js';
import { EXTERNAL_ID_RX, getOpenLibraryWork, isExternalSearchEnabled, searchOpenLibrary } from '../utils/openLibrary.js';
import { serializeRecommendations } from '../utils/serialize.js';
import { accentInsensitiveRegex, bookKey, cleanIsbn, escapeRegex, isValidIsbn, normalizeKey } from '../utils/text.js';

const LOCAL_LIMIT = 30;
const POPULAR = { ratingsCount: -1, averageRating: -1, title: 1 };

/**
 * Recherche dans le catalogue BookNest (source principale).
 * - title : titre en premier rang, puis description en second rang ;
 * - author / genre : champ correspondant.
 * Insensible à la casse et aux accents.
 */
async function searchLocal(q, type) {
  const rx = accentInsensitiveRegex(q);
  if (type === 'author') return Book.find({ authors: rx }).sort(POPULAR).limit(LOCAL_LIMIT);
  if (type === 'genre') return Book.find({ genres: rx }).sort(POPULAR).limit(LOCAL_LIMIT);
  const byTitle = await Book.find({ title: rx }).sort(POPULAR).limit(LOCAL_LIMIT);
  const byDescription = await Book.find({ _id: { $nin: byTitle.map((b) => b._id) }, description: rx })
    .sort(POPULAR)
    .limit(Math.max(LOCAL_LIMIT - byTitle.length, 0));
  return [...byTitle, ...byDescription];
}

/**
 * GET /api/books/search — catalogue local d'abord, puis (optionnellement) Open Library.
 * Les résultats externes sont dédupliqués (externalId, puis titre + auteur normalisés)
 * et un échec d'Open Library est silencieux (externalAvailable: false).
 */
export async function search(req, res) {
  const q = req.query.q.trim();
  const type = req.query.type || 'title';
  const viewerId = req.user?._id;

  const local = await searchLocal(q, type);
  const localResults = local.map((b) => ({ ...b.toPublic(viewerId), source: 'booknest' }));
  const externalResults = [];
  const externalEnabled = isExternalSearchEnabled();
  let externalAvailable = false;

  if (externalEnabled) {
    try {
      const items = await searchOpenLibrary(q, type);
      externalAvailable = true;
      const seenIds = new Set(localResults.map((r) => r.externalId).filter(Boolean));
      const seenKeys = new Set(localResults.map((r) => bookKey(r.title, r.authors)));
      // Livres déjà importés mais non trouvés par la recherche locale : on renvoie la fiche locale.
      const imported = await Book.find({ externalId: { $in: items.map((i) => i.externalId) } });
      const byExternalId = new Map(imported.map((b) => [b.externalId, b]));
      for (const item of items) {
        const key = bookKey(item.title, item.authors);
        if (seenIds.has(item.externalId) || seenKeys.has(key)) continue;
        seenIds.add(item.externalId);
        seenKeys.add(key);
        const known = byExternalId.get(item.externalId);
        if (known) localResults.push({ ...known.toPublic(viewerId), source: 'booknest' });
        else externalResults.push({ ...item, id: null, averageRating: 0, ratingsCount: 0, myRating: null, canEdit: false });
      }
    } catch (err) {
      if (process.env.NODE_ENV !== 'test') console.warn('[books] Open Library indisponible :', err.message);
    }
  }

  res.json({
    query: q,
    type,
    results: [...localResults, ...externalResults],
    localCount: localResults.length,
    externalCount: externalResults.length,
    externalEnabled,
    externalAvailable,
  });
}

export async function listBooks(req, res) {
  const { q, genre, sort = 'popular' } = req.query;
  const filter = {};
  if (q) {
    const rx = accentInsensitiveRegex(String(q));
    filter.$or = [{ title: rx }, { authors: rx }];
  }
  if (genre) filter.genres = new RegExp(`^${escapeRegex(String(genre))}$`, 'i');
  const sortSpec = sort === 'rating' ? { averageRating: -1, ratingsCount: -1 } : sort === 'recent' ? { createdAt: -1 } : POPULAR;
  const books = await Book.find(filter).sort(sortSpec).limit(Math.min(Number(req.query.limit) || 60, 100));
  res.json({ books: books.map((b) => b.toPublic(req.user?._id)) });
}

export async function listGenres(_req, res) {
  const genres = await Book.distinct('genres');
  res.json({ genres: genres.filter(Boolean).sort((a, b) => a.localeCompare(b, 'fr')) });
}

export async function getBook(req, res) {
  const book = await Book.findById(req.params.id);
  if (!book) throw new HttpError(404, 'Livre introuvable');
  const recs = await Recommendation.find({ book: book._id }).sort({ createdAt: -1 }).limit(50).populate('user', 'username').populate('book');
  res.json({ book: book.toPublic(req.user?._id), recommendations: await serializeRecommendations(recs, req.user?._id) });
}

/**
 * POST /api/books — crée un livre « from scratch » ou importe un résultat Open Library (externalId).
 * 201 si créé, 200 avec le livre existant si doublon (même externalId ou même titre + auteur).
 */
export async function createBook(req, res) {
  const { book, created } = await findOrCreateBook(req.body, req.user._id);
  res.status(created ? 201 : 200).json({
    book: book.toPublic(req.user._id),
    created,
    ...(created ? {} : { message: 'Ce livre existe déjà dans le catalogue BookNest' }),
  });
}

/** PUT /api/books/:id — modification réservée au créateur de la fiche. */
export async function updateBook(req, res) {
  const book = await Book.findById(req.params.id);
  if (!book) throw new HttpError(404, 'Livre introuvable');
  if (!book.addedBy || !book.addedBy.equals(req.user._id)) throw new HttpError(403, 'Seul le lecteur qui a ajouté ce livre peut le modifier');
  const fields = pickBookFields(req.body, { partial: true });
  if (fields.title !== undefined && !fields.title) throw new HttpError(400, 'Le titre est requis');
  const title = fields.title ?? book.title;
  const authors = fields.authors ?? book.authors;
  if (fields.title !== undefined || fields.authors !== undefined) {
    const dup = await findDuplicate(title, authors, book._id);
    if (dup) throw new HttpError(409, 'Un autre livre avec ce titre et cet auteur existe déjà');
  }
  book.set(fields);
  await book.save();
  res.json({ book: book.toPublic(req.user._id) });
}

/** Recherche un doublon : même titre (casse/accents ignorés) et au moins un auteur commun. */
export async function findDuplicate(title, authors = [], excludeId = null) {
  if (!title?.trim()) return null;
  const candidates = await Book.find({
    title: accentInsensitiveRegex(title, { anchored: true }),
    ...(excludeId ? { _id: { $ne: excludeId } } : {}),
  }).limit(20);
  const keys = new Set(authors.map(normalizeKey).filter(Boolean));
  return candidates.find((b) => !keys.size || b.authors.some((a) => keys.has(normalizeKey(a)))) || null;
}

/** Retourne { book, created } — utilisé par POST /api/books et par la création de recommandations. */
export async function findOrCreateBook(data, userId) {
  if (data.externalId) {
    const externalId = String(data.externalId).trim();
    if (!EXTERNAL_ID_RX.test(externalId)) throw new HttpError(400, 'Identifiant externe invalide');
    const existing = await Book.findOne({ externalId });
    if (existing) return { book: existing, created: false };

    let payload;
    if (!String(data.title || '').trim()) {
      let remote;
      try {
        remote = await getOpenLibraryWork(externalId);
      } catch {
        throw new HttpError(400, "Open Library est injoignable : impossible d'importer ce livre pour le moment. Ajoutez-le à la main.");
      }
      if (!remote) throw new HttpError(404, 'Livre introuvable sur Open Library');
      payload = pickBookFields(remote);
    } else {
      payload = pickBookFields(data);
    }
    const dup = await findDuplicate(payload.title, payload.authors);
    if (dup) {
      if (!dup.externalId) {
        dup.externalId = externalId;
        await dup.save();
      }
      return { book: dup, created: false };
    }
    try {
      const book = await Book.create({ ...payload, externalId, source: 'openlibrary', addedBy: userId });
      return { book, created: true };
    } catch (err) {
      if (err.code === 11000) {
        const book = await Book.findOne({ externalId });
        if (book) return { book, created: false };
      }
      throw err;
    }
  }

  const fields = pickBookFields(data);
  if (!fields.title) throw new HttpError(400, 'Le titre du livre est requis');
  const dup = await findDuplicate(fields.title, fields.authors);
  if (dup) return { book: dup, created: false };
  const book = await Book.create({ ...fields, source: 'booknest', addedBy: userId });
  return { book, created: true };
}

export function normalizeList(v, { max = 10, maxLength = 120 } = {}) {
  if (v === undefined || v === null || v === '') return [];
  const arr = Array.isArray(v) ? v : String(v).split(',');
  const seen = new Set();
  const out = [];
  for (const raw of arr) {
    const s = String(raw).trim().replace(/\s+/g, ' ').slice(0, maxLength);
    const k = normalizeKey(s);
    if (!s || seen.has(k)) continue;
    seen.add(k);
    out.push(s);
  }
  return out.slice(0, max);
}

/**
 * Normalise les champs modifiables d'un livre. En mode partiel, seuls les champs présents sont renvoyés.
 * Les valeurs invalides non bloquantes (couverture non https, ISBN invalide) sont ignorées.
 */
export function pickBookFields(d = {}, { partial = false } = {}) {
  const has = (k) => !partial || d[k] !== undefined;
  const out = {};
  if (has('title')) out.title = String(d.title || '').trim().slice(0, 300);
  if (has('authors')) out.authors = normalizeList(d.authors);
  if (has('genres')) out.genres = normalizeList(d.genres, { max: 8, maxLength: 40 });
  if (has('description')) out.description = String(d.description || '').trim().slice(0, 5000);
  if (has('coverUrl')) out.coverUrl = /^https:\/\/\S+$/i.test(String(d.coverUrl || '').trim()) ? String(d.coverUrl).trim() : '';
  if (has('isbn')) out.isbn = isValidIsbn(d.isbn) ? cleanIsbn(d.isbn) : '';
  if (has('publishedDate')) out.publishedDate = String(d.publishedDate ?? '').trim().slice(0, 10);
  if (has('pageCount')) {
    const n = Number(d.pageCount);
    out.pageCount = Number.isInteger(n) && n > 0 ? n : undefined;
  }
  return out;
}

export async function rateBook(req, res) {
  const book = await Book.findById(req.params.id);
  if (!book) throw new HttpError(404, 'Livre introuvable');
  book.setUserRating(req.user._id, Number(req.body.value));
  await book.save();
  res.json({ book: book.toPublic(req.user._id) });
}
