import { describe, expect, it, vi } from 'vitest';
import Book from '../src/models/Book.js';
import { api, mockFetchJson, mockFetchRoutes, olDoc, registerUser } from './helpers.js';

const OL_SEARCH = /^https:\/\/openlibrary\.org\/search\.json/;

describe('Recherche : catalogue BookNest en priorité', () => {
  it('cherche par titre, puis dans la description (second rang), sans tenir compte des accents', async () => {
    vi.stubGlobal('fetch', vi.fn(mockFetchJson({ docs: [] })));
    await Book.create({ title: 'Chants d’ombre', authors: ['Léopold Sédar Senghor'], genres: ['Poésie'], description: 'Premier recueil.' });
    await Book.create({ title: 'Éthiopiques', authors: ['Léopold Sédar Senghor'], description: 'Poèmes de Senghor à dire au son de la kora.' });
    await Book.create({ title: "L'Étranger", authors: ['Albert Camus'], genres: ['Roman'], ratingsCount: 3 });

    const byTitle = await api().get('/api/books/search').query({ q: 'etranger' });
    expect(byTitle.status).toBe(200);
    expect(byTitle.body.results.map((b) => b.title)).toEqual(["L'Étranger"]);
    expect(byTitle.body.results[0]).toMatchObject({ source: 'booknest', authors: ['Albert Camus'] });
    expect(byTitle.body.results[0].id).toBeTruthy();

    const titleThenDesc = await api().get('/api/books/search').query({ q: 'senghor', type: 'title' });
    expect(titleThenDesc.body.results.map((b) => b.title)).toEqual(['Éthiopiques']);

    const byAuthor = await api().get('/api/books/search').query({ q: 'SEDAR', type: 'author' });
    expect(byAuthor.body.results).toHaveLength(2);
    expect(byAuthor.body.localCount).toBe(2);

    const byGenre = await api().get('/api/books/search').query({ q: 'poesie', type: 'genre' });
    expect(byGenre.body.results.map((b) => b.title)).toEqual(['Chants d’ombre']);
  });

  it('ajoute les résultats Open Library après les locaux, dédupliqués (externalId puis titre + auteur)', async () => {
    await Book.create({ title: 'Dune', authors: ['Frank Herbert'], genres: ['Science-fiction'], ratingsCount: 2, averageRating: 4.5 });
    await Book.create({ title: 'Dune Messiah', authors: ['Frank Herbert'], externalId: 'ol:/works/OL2W' });
    const fetchMock = vi.fn(
      mockFetchJson({
        docs: [
          olDoc('OL1W', 'DUNE', { authors: ['Frank Herbert'] }), // doublon titre + auteur
          olDoc('OL2W', 'Dune Messiah (édition OL)'), // doublon externalId
          olDoc('OL3W', 'Children of Dune', { authors: ['Frank Herbert'], cover_i: 999 }),
          olDoc('OL3W', 'Children of Dune', { authors: ['Frank Herbert'] }), // doublon interne
          olDoc('OL4W', 'Dune: The Butlerian Jihad', { cover_i: null }),
        ],
      })
    );
    vi.stubGlobal('fetch', fetchMock);

    const res = await api().get('/api/books/search').query({ q: 'dune', type: 'title' });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ externalEnabled: true, externalAvailable: true, localCount: 2, externalCount: 2 });
    expect(res.body.results.map((r) => [r.title, r.source])).toEqual([
      ['Dune', 'booknest'],
      ['Dune Messiah', 'booknest'],
      ['Children of Dune', 'openlibrary'],
      ['Dune: The Butlerian Jihad', 'openlibrary'],
    ]);
    const ext = res.body.results[2];
    expect(ext).toMatchObject({ id: null, externalId: 'ol:/works/OL3W', authors: ['Frank Herbert'], isbn: '9781234567897', publishedDate: '2020', pageCount: 300 });
    expect(ext.coverUrl).toBe('https://covers.openlibrary.org/b/id/999-L.jpg');
    expect(res.body.results[3].coverUrl).toBe('');

    const [url, init] = fetchMock.mock.calls[0];
    const called = new URL(String(url));
    expect(called.origin + called.pathname).toBe('https://openlibrary.org/search.json');
    expect(called.searchParams.get('title')).toBe('dune');
    expect(called.searchParams.get('fields')).toContain('cover_i');
    expect(init.headers['User-Agent']).toBe('BookNest/1.0 (booknest.okemamy.com)');
    expect(init.signal).toBeTruthy();

    await api().get('/api/books/search').query({ q: 'Herbert', type: 'author' });
    expect(new URL(String(fetchMock.mock.calls[1][0])).searchParams.get('author')).toBe('Herbert');
    await api().get('/api/books/search').query({ q: 'fantasy', type: 'genre' });
    expect(new URL(String(fetchMock.mock.calls[2][0])).searchParams.get('subject')).toBe('fantasy');
  });

  it("échec d'Open Library (réseau, 429) : seuls les résultats locaux, externalAvailable false", async () => {
    await Book.create({ title: 'Fondation', authors: ['Isaac Asimov'], genres: ['Science-fiction'] });
    vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('network down'); }));
    const down = await api().get('/api/books/search').query({ q: 'asimov', type: 'author' });
    expect(down.status).toBe(200);
    expect(down.body).toMatchObject({ externalEnabled: true, externalAvailable: false, externalCount: 0 });
    expect(down.body.results.map((b) => b.title)).toEqual(['Fondation']);

    vi.stubGlobal('fetch', vi.fn(mockFetchJson({}, { status: 429 })));
    const limited = await api().get('/api/books/search').query({ q: 'fondation' });
    expect(limited.body.externalAvailable).toBe(false);
    expect(limited.body.results).toHaveLength(1);
  });

  it("EXTERNAL_BOOK_SEARCH=false : aucun appel à Open Library", async () => {
    process.env.EXTERNAL_BOOK_SEARCH = 'false';
    try {
      const fetchMock = vi.fn(mockFetchJson({ docs: [olDoc('OL9W', 'Externe')] }));
      vi.stubGlobal('fetch', fetchMock);
      await Book.create({ title: 'Local seulement' });
      const res = await api().get('/api/books/search').query({ q: 'local' });
      expect(res.body).toMatchObject({ externalEnabled: false, externalAvailable: false });
      expect(res.body.results.map((b) => b.title)).toEqual(['Local seulement']);
      expect(fetchMock).not.toHaveBeenCalled();
    } finally {
      delete process.env.EXTERNAL_BOOK_SEARCH;
    }
  });

  it('valide les paramètres de recherche', async () => {
    expect((await api().get('/api/books/search')).status).toBe(400);
    expect((await api().get('/api/books/search').query({ q: 'a', type: 'isbn' })).status).toBe(400);
  });
});

describe('Import Open Library (externalId)', () => {
  it('importe un résultat avec ses données, de façon idempotente', async () => {
    const { auth } = await registerUser();
    const payload = { externalId: 'ol:/works/OL45804W', title: 'Fantastic Mr Fox', authors: ['Roald Dahl'], coverUrl: 'https://covers.openlibrary.org/b/id/1-L.jpg' };
    const a = await api().post('/api/books').set(auth).send(payload);
    expect(a.status).toBe(201);
    expect(a.body.book).toMatchObject({ title: 'Fantastic Mr Fox', externalId: 'ol:/works/OL45804W', source: 'openlibrary', canEdit: true });
    const b = await api().post('/api/books').set(auth).send(payload);
    expect(b.status).toBe(200);
    expect(b.body.created).toBe(false);
    expect(b.body.book.id).toBe(a.body.book.id);
    expect(await Book.countDocuments()).toBe(1);
  });

  it("récupère l'œuvre et ses auteurs si seul l'externalId est fourni", async () => {
    const fetchMock = vi.fn(
      mockFetchRoutes([
        [/\/works\/OL7W\.json$/, { title: 'Œuvre distante', authors: [{ author: { key: '/authors/OL1A' } }], description: { value: 'Résumé OL' }, subjects: ['Roman'], covers: [42], first_publish_date: 'May 1999' }],
        [/\/authors\/OL1A\.json$/, { name: 'Autrice OL' }],
      ])
    );
    vi.stubGlobal('fetch', fetchMock);
    const { auth } = await registerUser();
    const res = await api().post('/api/books').set(auth).send({ externalId: 'ol:/works/OL7W' });
    expect(res.status).toBe(201);
    expect(res.body.book).toMatchObject({ title: 'Œuvre distante', authors: ['Autrice OL'], description: 'Résumé OL', genres: ['Roman'], publishedDate: '1999', coverUrl: 'https://covers.openlibrary.org/b/id/42-L.jpg' });
    expect(fetchMock.mock.calls[0][1].headers['User-Agent']).toContain('BookNest/1.0');
    const again = await api().post('/api/books').set(auth).send({ externalId: 'ol:/works/OL7W' });
    expect(again.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('400 si Open Library est injoignable, 404 si œuvre inconnue, 400 si identifiant invalide', async () => {
    const { auth } = await registerUser();
    vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('timeout'); }));
    expect((await api().post('/api/books').set(auth).send({ externalId: 'ol:/works/OL8W' })).status).toBe(400);
    vi.stubGlobal('fetch', vi.fn(mockFetchJson({}, { status: 404 })));
    expect((await api().post('/api/books').set(auth).send({ externalId: 'ol:/works/OL8W' })).status).toBe(404);
    expect((await api().post('/api/books').set(auth).send({ externalId: '../../etc', title: 'x' })).status).toBe(400);
  });
});

describe('Création et modification de livres', () => {
  const full = {
    title: 'Le Ventre de l’Atlantique',
    authors: ['Fatou Diome'],
    genres: ['Roman', 'Littérature africaine'],
    description: 'Salie vit à Strasbourg...',
    coverUrl: 'https://example.org/cover.jpg',
    isbn: '978-2-253-10907-5',
    publishedDate: '2003',
    pageCount: 272,
  };

  it('crée un livre from scratch (201), renvoie le livre existant pour un doublon (200)', async () => {
    expect((await api().post('/api/books').send({ title: 'X' })).status).toBe(401);
    const { auth } = await registerUser();
    const res = await api().post('/api/books').set(auth).send(full);
    expect(res.status).toBe(201);
    expect(res.body.created).toBe(true);
    expect(res.body.book).toMatchObject({ ...full, isbn: '9782253109075', source: 'booknest', externalId: null, canEdit: true, averageRating: 0 });

    const dup = await api().post('/api/books').set(auth).send({ title: "le ventre de l'atlantique", authors: 'fatou diome, Autre' });
    expect(dup.status).toBe(200);
    expect(dup.body.created).toBe(false);
    expect(dup.body.message).toMatch(/existe déjà/);
    expect(dup.body.book.id).toBe(res.body.book.id);

    const other = await api().post('/api/books').set(auth).send({ title: 'Le Ventre de l’Atlantique', authors: ['Quelqu’un d’autre'] });
    expect(other.status).toBe(201);

    const csv = await api().post('/api/books').set(auth).send({ title: 'Mon livre', authors: 'A, B, a' });
    expect(csv.body.book.authors).toEqual(['A', 'B']);
    expect(csv.body.book.coverUrl).toBe('');
  });

  it('valide les champs (400)', async () => {
    const { auth } = await registerUser();
    const post = (b) => api().post('/api/books').set(auth).send(b);
    expect((await post({})).status).toBe(400);
    expect((await post({ title: '   ' })).status).toBe(400);
    expect((await post({ title: 'T', coverUrl: 'http://insecure.example/c.jpg' })).status).toBe(400);
    expect((await post({ title: 'T', isbn: '9782253109076' })).status).toBe(400);
    expect((await post({ title: 'T', isbn: '123' })).status).toBe(400);
    expect((await post({ title: 'T', publishedDate: '3020' })).status).toBe(400);
    expect((await post({ title: 'T', pageCount: -3 })).status).toBe(400);
    expect((await post({ title: 'T', authors: [42] })).status).toBe(400);
    expect((await post({ title: 'T', isbn: '2-07-036002-4' })).status).toBe(201); // ISBN-10 valide
  });

  it('PUT : réservé au créateur (200), 403 pour les autres, 401 sans jeton, 404 si inconnu', async () => {
    const owner = await registerUser();
    const other = await registerUser();
    const { body } = await api().post('/api/books').set(owner.auth).send({ title: 'Brouillon', authors: ['Moi'] });
    const id = body.book.id;

    expect((await api().put(`/api/books/${id}`).send({ title: 'x' })).status).toBe(401);
    const forbidden = await api().put(`/api/books/${id}`).set(other.auth).send({ title: 'Piratage' });
    expect(forbidden.status).toBe(403);
    const view = await api().get(`/api/books/${id}`).set(other.auth);
    expect(view.body.book.canEdit).toBe(false);

    const upd = await api().put(`/api/books/${id}`).set(owner.auth).send({ title: 'Version finale', genres: ['Essai'], pageCount: 120, coverUrl: '' });
    expect(upd.status).toBe(200);
    expect(upd.body.book).toMatchObject({ title: 'Version finale', authors: ['Moi'], genres: ['Essai'], pageCount: 120, canEdit: true });
    expect((await api().put(`/api/books/${id}`).set(owner.auth).send({ title: '' })).status).toBe(400);
    expect((await api().put(`/api/books/${id}`).set(owner.auth).send({ isbn: 'abc' })).status).toBe(400);

    await api().post('/api/books').set(owner.auth).send({ title: 'Existant', authors: ['Moi'] });
    expect((await api().put(`/api/books/${id}`).set(owner.auth).send({ title: 'existant' })).status).toBe(409);
    expect((await api().put('/api/books/507f1f77bcf86cd799439011').set(owner.auth).send({ title: 'x' })).status).toBe(404);
  });
});

describe('Fiche livre et notes', () => {
  it('affiche le détail, 404 si inconnu', async () => {
    const book = await Book.create({ title: 'Détail', authors: ['Z'], description: 'desc' });
    const res = await api().get(`/api/books/${book._id}`);
    expect(res.status).toBe(200);
    expect(res.body.book).toMatchObject({ title: 'Détail', description: 'desc', averageRating: 0, source: 'booknest', canEdit: false });
    expect(res.body.recommendations).toEqual([]);
    expect((await api().get('/api/books/507f1f77bcf86cd799439011')).status).toBe(404);
    expect((await api().get('/api/books/pas-un-id')).status).toBe(404);
  });

  it('met à jour la note moyenne : un vote par utilisateur, modifiable', async () => {
    const book = await Book.create({ title: 'À noter' });
    const u1 = await registerUser();
    const u2 = await registerUser();

    expect((await api().post(`/api/books/${book._id}/rate`).send({ value: 5 })).status).toBe(401);
    expect((await api().post(`/api/books/${book._id}/rate`).set(u1.auth).send({ value: 6 })).status).toBe(400);

    let res = await api().post(`/api/books/${book._id}/rate`).set(u1.auth).send({ value: 5 });
    expect(res.status).toBe(200);
    expect(res.body.book).toMatchObject({ averageRating: 5, ratingsCount: 1, myRating: 5 });

    res = await api().post(`/api/books/${book._id}/rate`).set(u2.auth).send({ value: 2 });
    expect(res.body.book).toMatchObject({ averageRating: 3.5, ratingsCount: 2 });

    res = await api().post(`/api/books/${book._id}/rate`).set(u1.auth).send({ value: 3 });
    expect(res.body.book).toMatchObject({ averageRating: 2.5, ratingsCount: 2, myRating: 3 });

    const detail = await api().get(`/api/books/${book._id}`).set(u2.auth);
    expect(detail.body.book.myRating).toBe(2);
    expect((await api().post('/api/books/507f1f77bcf86cd799439011/rate').set(u1.auth).send({ value: 3 })).status).toBe(404);
  });

  it('liste les livres et les genres', async () => {
    await Book.create({ title: 'A', genres: ['Roman'], ratingsCount: 1 });
    await Book.create({ title: 'B', genres: ['Essai', 'Roman'], ratingsCount: 3 });
    const list = await api().get('/api/books');
    expect(list.body.books.map((b) => b.title)).toEqual(['B', 'A']);
    const filtered = await api().get('/api/books').query({ genre: 'essai' });
    expect(filtered.body.books).toHaveLength(1);
    const genres = await api().get('/api/books/genres');
    expect(genres.body.genres).toEqual(['Essai', 'Roman']);
  });
});
