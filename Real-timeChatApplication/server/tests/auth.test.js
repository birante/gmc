import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { auth, clearDb, registerUser, startDb, stopDb } from './helpers.js';

const app = createApp();

beforeAll(startDb);
afterEach(clearDb);
afterAll(stopDb);

describe('GET /up', () => {
  it('répond 200 OK sans authentification', async () => {
    const res = await request(app).get('/up');
    expect(res.status).toBe(200);
    expect(res.text).toBe('OK');
  });
});

describe('Auth', () => {
  it('inscrit un utilisateur et renvoie un jeton', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'awa', email: 'Awa@Test.sn', password: 'secret123' });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    expect(res.body.user).toMatchObject({ username: 'awa', email: 'awa@test.sn' });
    expect(res.body.user.avatarColor).toMatch(/^#/);
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it('refuse une inscription invalide (400)', async () => {
    const res = await request(app).post('/api/auth/register').send({ username: 'a', email: 'pas-un-email', password: '1' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeTruthy();
  });

  it('refuse un email ou un pseudo déjà utilisé (409)', async () => {
    await registerUser(app, { username: 'awa', email: 'awa@test.sn' });
    const dupEmail = await request(app).post('/api/auth/register').send({ username: 'autre', email: 'awa@test.sn', password: 'secret123' });
    expect(dupEmail.status).toBe(409);
    const dupName = await request(app).post('/api/auth/register').send({ username: 'AWA', email: 'x@test.sn', password: 'secret123' });
    expect(dupName.status).toBe(409);
  });

  it('connecte avec de bons identifiants et refuse les mauvais', async () => {
    await registerUser(app, { username: 'moussa', email: 'moussa@test.sn', password: 'secret123' });
    const ok = await request(app).post('/api/auth/login').send({ email: 'moussa@test.sn', password: 'secret123' });
    expect(ok.status).toBe(200);
    expect(ok.body.token).toBeTruthy();
    const bad = await request(app).post('/api/auth/login').send({ email: 'moussa@test.sn', password: 'mauvais' });
    expect(bad.status).toBe(401);
  });

  it('GET /me exige un jeton valide', async () => {
    const { token, user } = await registerUser(app);
    expect((await request(app).get('/api/auth/me')).status).toBe(401);
    expect((await request(app).get('/api/auth/me').set(auth('faux'))).status).toBe(401);
    const res = await request(app).get('/api/auth/me').set(auth(token));
    expect(res.status).toBe(200);
    expect(res.body.user.id).toBe(user.id);
  });

  it('POST /logout renvoie 204', async () => {
    const { token } = await registerUser(app);
    const res = await request(app).post('/api/auth/logout').set(auth(token));
    expect(res.status).toBe(204);
  });

  it('renvoie 404 JSON pour une route API inconnue', async () => {
    const res = await request(app).get('/api/inexistant');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeTruthy();
  });
});
