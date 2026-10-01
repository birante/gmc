import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { startDb, stopDb, clearDb, api, registerUser, auth } from './setup.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(clearDb);

describe('GET /up', () => {
  it('répond 200 OK quand la base est connectée', async () => {
    const res = await api().get('/up');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });
});

describe('Auth', () => {
  it('inscrit un utilisateur et renvoie un jeton sans le hash', async () => {
    const res = await api().post('/api/auth/register').send({ name: 'Awa', email: 'Awa@Test.sn', password: 'secret123' });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    expect(res.body.user.email).toBe('awa@test.sn');
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it('refuse un email déjà utilisé (409)', async () => {
    await registerUser({ email: 'dup@test.sn' });
    const res = await api().post('/api/auth/register').send({ name: 'Dup', email: 'dup@test.sn', password: 'secret123' });
    expect(res.status).toBe(409);
    expect(res.body.error).toBeTruthy();
  });

  it('valide les champs d’inscription (400)', async () => {
    const res = await api().post('/api/auth/register').send({ name: 'A', email: 'pas-un-email', password: '1' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeTruthy();
  });

  it('connecte avec les bons identifiants', async () => {
    await registerUser({ email: 'login@test.sn', password: 'secret123' });
    const res = await api().post('/api/auth/login').send({ email: 'login@test.sn', password: 'secret123' });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeTruthy();
  });

  it('refuse un mauvais mot de passe (401)', async () => {
    await registerUser({ email: 'bad@test.sn' });
    const res = await api().post('/api/auth/login').send({ email: 'bad@test.sn', password: 'wrongpass' });
    expect(res.status).toBe(401);
  });

  it('GET /api/auth/me renvoie l’utilisateur courant', async () => {
    const { token, user } = await registerUser();
    const res = await api().get('/api/auth/me').set(auth(token));
    expect(res.status).toBe(200);
    expect(res.body.user.id).toBe(user.id);
  });

  it('GET /api/auth/me sans jeton ou avec jeton invalide -> 401', async () => {
    expect((await api().get('/api/auth/me')).status).toBe(401);
    expect((await api().get('/api/auth/me').set(auth('abc.def.ghi'))).status).toBe(401);
  });

  it('renvoie 404 JSON pour une route API inconnue', async () => {
    const res = await api().get('/api/inconnue');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeTruthy();
  });
});
