import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import jwt from 'jsonwebtoken';
import { startDb, stopDb, clearDb, api, createUser } from './helpers.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(clearDb);

describe('Healthcheck', () => {
  it('GET /up renvoie 200 OK quand la base est connectée', async () => {
    const res = await api().get('/up');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });

  it('les routes /api inconnues renvoient 404 JSON', async () => {
    const res = await api().get('/api/nope');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
  });

  it('la CSP autorise les images https et data', async () => {
    const res = await api().get('/up');
    expect(res.headers['content-security-policy']).toMatch(/img-src 'self' https: data:/);
  });
});

describe('Auth', () => {
  it("inscrit un utilisateur et renvoie un jeton sans le hash", async () => {
    const res = await api()
      .post('/api/auth/register')
      .send({ name: 'Awa', email: 'Awa@Test.dev', password: 'secret123' });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    expect(res.body.user.email).toBe('awa@test.dev');
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it('refuse un e-mail déjà utilisé (409)', async () => {
    await createUser({ email: 'dup@test.dev' });
    const res = await api().post('/api/auth/register').send({ name: 'Dup', email: 'dup@test.dev', password: 'secret123' });
    expect(res.status).toBe(409);
  });

  it('valide les champs (400)', async () => {
    const res = await api().post('/api/auth/register').send({ name: 'A', email: 'pasunemail', password: '123' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeTruthy();
    expect(res.body.details.length).toBeGreaterThan(0);
  });

  it('connecte avec les bons identifiants et refuse les mauvais', async () => {
    await createUser({ email: 'log@test.dev', password: 'password123' });
    const ok = await api().post('/api/auth/login').send({ email: 'log@test.dev', password: 'password123' });
    expect(ok.status).toBe(200);
    expect(ok.body.token).toBeTruthy();
    const ko = await api().post('/api/auth/login').send({ email: 'log@test.dev', password: 'mauvais' });
    expect(ko.status).toBe(401);
  });

  it('GET /api/auth/me restaure la session et exige un jeton', async () => {
    const { auth, user } = await createUser();
    const res = await api().get('/api/auth/me').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.user.id).toBe(user.id);
    expect((await api().get('/api/auth/me')).status).toBe(401);
    expect((await api().get('/api/auth/me').set('Authorization', 'Bearer faux')).status).toBe(401);
  });

  it('renvoie 401 avec un jeton expiré', async () => {
    const { user } = await createUser();
    const expired = jwt.sign({ sub: user.id }, 'test-secret', { expiresIn: -10 });
    const res = await api().get('/api/auth/me').set('Authorization', `Bearer ${expired}`);
    expect(res.status).toBe(401);
    expect(res.body.error).toMatch(/expirée/);
  });

  it('PUT /api/auth/me met à jour le profil et le mot de passe', async () => {
    const { auth } = await createUser({ email: 'prof@test.dev' });
    const res = await api().put('/api/auth/me').set(auth).send({ name: 'Nouveau Nom', bio: 'Ma bio' });
    expect(res.status).toBe(200);
    expect(res.body.user.name).toBe('Nouveau Nom');
    expect(res.body.user.bio).toBe('Ma bio');

    const bad = await api().put('/api/auth/me').set(auth).send({ currentPassword: 'faux', newPassword: 'nouveau123' });
    expect(bad.status).toBe(400);
    const good = await api().put('/api/auth/me').set(auth).send({ currentPassword: 'password123', newPassword: 'nouveau123' });
    expect(good.status).toBe(200);
    const login = await api().post('/api/auth/login').send({ email: 'prof@test.dev', password: 'nouveau123' });
    expect(login.status).toBe(200);
  });

  it('POST /api/auth/logout renvoie 204', async () => {
    const res = await api().post('/api/auth/logout');
    expect(res.status).toBe(204);
  });
});
