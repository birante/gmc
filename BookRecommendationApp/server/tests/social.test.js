import { describe, expect, it, vi } from 'vitest';
import Book from '../src/models/Book.js';
import Recommendation from '../src/models/Recommendation.js';
import User from '../src/models/User.js';
import { seedIfEmpty } from '../src/seed.js';
import { api, mockFetchJson, registerUser } from './helpers.js';

async function recommend(auth, payload) {
  return api().post('/api/recommendations').set(auth).send(payload);
}

describe('Recommandations', () => {
  it('crée une recommandation avec saisie manuelle et met à jour la note du livre', async () => {
    const { auth } = await registerUser();
    expect((await api().post('/api/recommendations').send({})).status).toBe(401);

    const res = await recommend(auth, {
      book: { title: 'Une si longue lettre', authors: ['Mariama Bâ'], description: 'Roman épistolaire', genres: ['Roman'] },
      rating: 5,
      review: 'Magnifique et bouleversant.',
    });
    expect(res.status).toBe(201);
    expect(res.body.recommendation).toMatchObject({ rating: 5, likesCount: 0, commentsCount: 0, likedByMe: false });
    expect(res.body.recommendation.book).toMatchObject({ title: 'Une si longue lettre', averageRating: 5, ratingsCount: 1 });

    const again = await recommend(auth, { bookId: res.body.recommendation.book.id, rating: 4, review: 'Encore !' });
    expect(again.status).toBe(409);
  });

  it('crée une recommandation depuis un résultat Open Library (import par externalId)', async () => {
    const fetchMock = vi.fn(mockFetchJson({}));
    vi.stubGlobal('fetch', fetchMock);
    const { auth } = await registerUser();
    const book = { externalId: 'ol:/works/OL1W', title: 'Depuis Open Library', authors: ['Auteur OL'], coverUrl: 'https://covers.openlibrary.org/b/id/1-L.jpg' };
    const res = await recommend(auth, { book, rating: 4, review: 'Très bon livre' });
    expect(res.status).toBe(201);
    expect(res.body.recommendation.book.title).toBe('Depuis Open Library');
    expect(await Book.countDocuments({ externalId: 'ol:/works/OL1W' })).toBe(1);
    expect((await Book.findOne({ externalId: 'ol:/works/OL1W' })).source).toBe('openlibrary');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('valide les données (400) et le livre (404)', async () => {
    const { auth } = await registerUser();
    expect((await recommend(auth, { book: { title: 'X' }, rating: 9, review: 'Bien' })).status).toBe(400);
    expect((await recommend(auth, { book: { title: 'X' }, rating: 3 })).status).toBe(400);
    expect((await recommend(auth, { rating: 3, review: 'Sans livre' })).status).toBe(400);
    expect((await recommend(auth, { bookId: '507f1f77bcf86cd799439011', rating: 3, review: 'Inconnu' })).status).toBe(404);
  });

  it("modifier/supprimer : réservé à l'auteur (403), 404 si inconnu", async () => {
    const owner = await registerUser();
    const other = await registerUser();
    const { body } = await recommend(owner.auth, { book: { title: 'Livre' }, rating: 4, review: 'Pas mal du tout' });
    const id = body.recommendation.id;

    expect((await api().patch(`/api/recommendations/${id}`).set(other.auth).send({ review: 'hack' })).status).toBe(403);
    expect((await api().delete(`/api/recommendations/${id}`).set(other.auth)).status).toBe(403);
    const upd = await api().patch(`/api/recommendations/${id}`).set(owner.auth).send({ rating: 2, review: 'Finalement bof' });
    expect(upd.status).toBe(200);
    expect(upd.body.recommendation).toMatchObject({ rating: 2, review: 'Finalement bof' });
    expect(upd.body.recommendation.book.averageRating).toBe(2);

    expect((await api().delete(`/api/recommendations/${id}`).set(owner.auth)).status).toBe(204);
    expect((await api().get(`/api/recommendations/${id}`)).status).toBe(404);
    expect((await api().delete('/api/recommendations/507f1f77bcf86cd799439011').set(owner.auth)).status).toBe(404);
  });

  it('like / unlike (idempotent)', async () => {
    const owner = await registerUser();
    const fan = await registerUser();
    const { body } = await recommend(owner.auth, { book: { title: 'Aimable' }, rating: 5, review: 'Super lecture' });
    const id = body.recommendation.id;
    expect((await api().post(`/api/recommendations/${id}/like`)).status).toBe(401);
    expect((await api().post(`/api/recommendations/${id}/like`).set(fan.auth)).body).toEqual({ liked: true, likesCount: 1 });
    expect((await api().post(`/api/recommendations/${id}/like`).set(fan.auth)).body.likesCount).toBe(1);
    const seen = await api().get(`/api/recommendations/${id}`).set(fan.auth);
    expect(seen.body.recommendation.likedByMe).toBe(true);
    expect((await api().delete(`/api/recommendations/${id}/like`).set(fan.auth)).body).toEqual({ liked: false, likesCount: 0 });
    expect((await api().post('/api/recommendations/507f1f77bcf86cd799439011/like').set(fan.auth)).status).toBe(404);
  });

  it('commentaires : ajout, liste, suppression par auteur seulement', async () => {
    const owner = await registerUser();
    const c1 = await registerUser();
    const c2 = await registerUser();
    const { body } = await recommend(owner.auth, { book: { title: 'Discutable' }, rating: 3, review: 'À débattre' });
    const id = body.recommendation.id;

    expect((await api().post(`/api/recommendations/${id}/comments`).send({ text: 'x' })).status).toBe(401);
    expect((await api().post(`/api/recommendations/${id}/comments`).set(c1.auth).send({ text: '  ' })).status).toBe(400);
    const created = await api().post(`/api/recommendations/${id}/comments`).set(c1.auth).send({ text: "Je ne suis pas d'accord" });
    expect(created.status).toBe(201);
    expect(created.body.comment.user.username).toBe(c1.user.username);

    const list = await api().get(`/api/recommendations/${id}/comments`);
    expect(list.body.comments).toHaveLength(1);
    const detail = await api().get(`/api/recommendations/${id}`);
    expect(detail.body.recommendation.commentsCount).toBe(1);
    expect(detail.body.comments).toHaveLength(1);

    const cid = created.body.comment.id;
    expect((await api().delete(`/api/comments/${cid}`).set(c2.auth)).status).toBe(403);
    expect((await api().delete(`/api/comments/${cid}`).set(c1.auth)).status).toBe(204);
    expect((await api().delete(`/api/comments/${cid}`).set(c1.auth)).status).toBe(404);
  });
});

describe('Suivi et profils', () => {
  it('follow / unfollow met à jour les deux côtés', async () => {
    const a = await registerUser({ username: 'reader_a' });
    const b = await registerUser({ username: 'reader_b' });
    expect((await api().post(`/api/users/${b.user.id}/follow`)).status).toBe(401);
    expect((await api().post(`/api/users/${a.user.id}/follow`).set(a.auth)).status).toBe(400);
    expect((await api().post('/api/users/507f1f77bcf86cd799439011/follow').set(a.auth)).status).toBe(404);

    const res = await api().post(`/api/users/${b.user.id}/follow`).set(a.auth);
    expect(res.body).toEqual({ following: true, followersCount: 1 });
    const profile = await api().get('/api/users/reader_b').set(a.auth);
    expect(profile.body.user).toMatchObject({ followersCount: 1, isFollowing: true, isMe: false });
    expect(profile.body.user.followers[0].username).toBe('reader_a');
    const me = await api().get('/api/auth/me').set(a.auth);
    expect(me.body.user.following).toEqual([b.user.id]);

    const un = await api().delete(`/api/users/${b.user.id}/follow`).set(a.auth);
    expect(un.body).toEqual({ following: false, followersCount: 0 });
  });

  it('page profil avec recommandations, 404 si inconnu', async () => {
    const a = await registerUser({ username: 'profil_test' });
    await recommend(a.auth, { book: { title: 'Livre du profil' }, rating: 4, review: 'Une belle découverte' });
    const res = await api().get('/api/users/profil_test');
    expect(res.status).toBe(200);
    expect(res.body.user.username).toBe('profil_test');
    expect(res.body.recommendations).toHaveLength(1);
    expect((await api().get('/api/users/inconnu')).status).toBe(404);
  });

  it('modifie sa bio et ses genres favoris', async () => {
    const a = await registerUser();
    expect((await api().patch('/api/users/me').send({ bio: 'x' })).status).toBe(401);
    const res = await api().patch('/api/users/me').set(a.auth).send({ bio: 'Lectrice', favoriteGenres: ['Roman', 'Roman', ' Essai '] });
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ bio: 'Lectrice', favoriteGenres: ['Roman', 'Essai'] });
  });

  it('liste / recherche des lecteurs', async () => {
    const a = await registerUser({ username: 'zoe_lit' });
    await registerUser({ username: 'marc' });
    const res = await api().get('/api/users').query({ q: 'mar' }).set(a.auth);
    expect(res.body.users.map((u) => u.username)).toEqual(['marc']);
  });
});

describe('Fil personnalisé', () => {
  it('exige une authentification', async () => {
    expect((await api().get('/api/feed')).status).toBe(401);
  });

  it('priorise les personnes suivies, les genres favoris et la popularité', async () => {
    const me = await registerUser({ username: 'moi', favoriteGenres: ['Science-fiction'] });
    const friend = await registerUser({ username: 'ami' });
    const stranger = await registerUser({ username: 'inconnu' });
    const fan1 = await registerUser();
    const fan2 = await registerUser();

    await api().post(`/api/users/${friend.user.id}/follow`).set(me.auth);

    const r1 = await recommend(stranger.auth, { book: { title: 'Hors sujet', genres: ['Cuisine'] }, rating: 3, review: 'Recettes sympas' });
    const r2 = await recommend(stranger.auth, { book: { title: 'Dune', genres: ['Science-fiction'] }, rating: 5, review: 'Culte absolu' });
    const r3 = await recommend(friend.auth, { book: { title: "Livre de l'ami", genres: ['Poésie'] }, rating: 4, review: 'Très beau recueil' });
    const r4 = await recommend(stranger.auth, { book: { title: 'Populaire', genres: ['Thriller'] }, rating: 4, review: 'Haletant de bout en bout' });
    const mine = await recommend(me.auth, { book: { title: 'Le mien', genres: ['Science-fiction'] }, rating: 4, review: 'Ma propre reco' });

    // r1 ancienne, r4 très likée
    await Recommendation.updateOne({ _id: r1.body.recommendation.id }, { createdAt: new Date(Date.now() - 30 * 86400000) });
    for (const f of [fan1, fan2]) await api().post(`/api/recommendations/${r4.body.recommendation.id}/like`).set(f.auth);

    const res = await api().get('/api/feed').set(me.auth);
    expect(res.status).toBe(200);
    const items = res.body.recommendations;
    const ids = items.map((r) => r.id);
    expect(ids).not.toContain(mine.body.recommendation.id);
    expect(ids).toHaveLength(4);
    expect(ids[ids.length - 1]).toBe(r1.body.recommendation.id);
    expect(items.find((r) => r.id === r3.body.recommendation.id).reasons).toContain('following');
    expect(items.find((r) => r.id === r2.body.recommendation.id).reasons).toContain('genre');
    expect(items.find((r) => r.id === r4.body.recommendation.id).reasons).toContain('popular');
    // trié par score décroissant
    const scores = items.map((r) => r.score);
    expect([...scores].sort((a, b) => b - a)).toEqual(scores);
    expect(ids[0]).toBe(r3.body.recommendation.id);
  });
});

describe('Seed de démonstration', () => {
  it("ne s'exécute que si la base est vide", async () => {
    expect(await seedIfEmpty({ log: false })).toBe(true);
    expect(await User.countDocuments()).toBe(3);
    expect(await Book.countDocuments()).toBeGreaterThanOrEqual(45);
    expect(await Recommendation.countDocuments()).toBeGreaterThanOrEqual(20);
    expect(await Recommendation.countDocuments()).toBeGreaterThan(5);
    expect(await seedIfEmpty({ log: false })).toBe(false);
    expect(await User.countDocuments()).toBe(3);

    const login = await api().post('/api/auth/login').send({ email: 'amina@booknest.app', password: 'password123' });
    expect(login.status).toBe(200);
    const feed = await api().get('/api/feed').set('Authorization', `Bearer ${login.body.token}`);
    expect(feed.body.recommendations.length).toBeGreaterThan(0);
    const book = await Book.findOne({ title: 'Dune' });
    expect(book.ratingsCount).toBe(2);
    expect(book.averageRating).toBe(4.5);
  });
});
