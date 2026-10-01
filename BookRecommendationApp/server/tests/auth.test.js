import { describe, expect, it } from 'vitest';
import { api, registerUser } from './helpers.js';

describe('Santé & statique', () => {
  it('GET /up renvoie 200 OK quand Mongo est connecté', async () => {
    const res = await api().get('/up');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });

  it('route API inconnue -> 404 JSON', async () => {
    const res = await api().get('/api/nope');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
  });

  it('autorise les images https dans la CSP', async () => {
    const res = await api().get('/up');
    expect(res.headers['content-security-policy']).toMatch(/img-src[^;]*https:/);
    expect(res.headers['content-security-policy']).toMatch(/img-src[^;]*data:/);
  });
});

describe('Authentification', () => {
  it('inscrit un utilisateur et renvoie un JWT sans le hash', async () => {
    const res = await api().post('/api/auth/register').send({ username: 'alice', email: 'Alice@Test.dev', password: 'secret12', favoriteGenres: ['Roman'] });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    expect(res.body.user).toMatchObject({ username: 'alice', email: 'alice@test.dev', favoriteGenres: ['Roman'] });
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it('refuse les doublons (409) et les données invalides (400)', async () => {
    await registerUser({ username: 'bob', email: 'bob@test.dev' });
    const dup = await api().post('/api/auth/register').send({ username: 'bob', email: 'other@test.dev', password: 'secret12' });
    expect(dup.status).toBe(409);
    const bad = await api().post('/api/auth/register').send({ username: 'x', email: 'pas-un-email', password: '1' });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toBeTruthy();
  });

  it('connecte avec les bons identifiants et refuse les mauvais', async () => {
    await registerUser({ username: 'carol', email: 'carol@test.dev', password: 'goodpass' });
    const ok = await api().post('/api/auth/login').send({ email: 'carol@test.dev', password: 'goodpass' });
    expect(ok.status).toBe(200);
    expect(ok.body.user.username).toBe('carol');
    const ko = await api().post('/api/auth/login').send({ email: 'carol@test.dev', password: 'wrong' });
    expect(ko.status).toBe(401);
  });

  it('protège /api/auth/me (401 sans jeton ou jeton invalide)', async () => {
    expect((await api().get('/api/auth/me')).status).toBe(401);
    expect((await api().get('/api/auth/me').set('Authorization', 'Bearer abc')).status).toBe(401);
    const { auth } = await registerUser();
    const me = await api().get('/api/auth/me').set(auth);
    expect(me.status).toBe(200);
    expect(me.body.user.username).toMatch(/^user/);
  });
});
