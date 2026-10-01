import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { api, startDb, stopDb, resetDb } from './setup.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(resetDb);

describe('Auth', () => {
  it('inscrit, connecte et renvoie le profil', async () => {
    const reg = await api().post('/api/auth/register').send({ name: 'Moussa', email: 'MOUSSA@test.sn', password: 'secret123' });
    expect(reg.status).toBe(201);
    expect(reg.body.token).toBeTruthy();
    expect(reg.body.user).toMatchObject({ email: 'moussa@test.sn', role: 'client' });
    expect(reg.body.user.passwordHash).toBeUndefined();

    const login = await api().post('/api/auth/login').send({ email: 'moussa@test.sn', password: 'secret123' });
    expect(login.status).toBe(200);

    const me = await api().get('/api/auth/me').set('Authorization', `Bearer ${login.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body.user.name).toBe('Moussa');
  });

  it("n'autorise pas l'auto-attribution du rôle admin", async () => {
    const reg = await api().post('/api/auth/register').send({ name: 'Pirate', email: 'p@test.sn', password: 'secret123', role: 'admin' });
    expect(reg.status).toBe(201);
    expect(reg.body.user.role).toBe('client');
  });

  it('refuse un email déjà utilisé (409)', async () => {
    const body = { name: 'Moussa', email: 'm@test.sn', password: 'secret123' };
    await api().post('/api/auth/register').send(body);
    const res = await api().post('/api/auth/register').send(body);
    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/déjà/);
  });

  it('valide les entrées (400)', async () => {
    const res = await api().post('/api/auth/register').send({ name: 'M', email: 'pas-un-email', password: '1' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeTruthy();
  });

  it('refuse un mauvais mot de passe (401)', async () => {
    await api().post('/api/auth/register').send({ name: 'Moussa', email: 'm@test.sn', password: 'secret123' });
    const res = await api().post('/api/auth/login').send({ email: 'm@test.sn', password: 'mauvais' });
    expect(res.status).toBe(401);
  });

  it('refuse /me sans jeton ou avec un jeton invalide (401)', async () => {
    expect((await api().get('/api/auth/me')).status).toBe(401);
    expect((await api().get('/api/auth/me').set('Authorization', 'Bearer abc')).status).toBe(401);
  });
});

describe('Santé et routes', () => {
  it('GET /up renvoie OK', async () => {
    const res = await api().get('/up');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });

  it('route API inconnue -> 404 JSON', async () => {
    const res = await api().get('/api/nope');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeTruthy();
  });

  it('CSP autorise les images https', async () => {
    const res = await api().get('/up');
    expect(res.headers['content-security-policy']).toMatch(/img-src 'self' https: data:/);
  });
});
