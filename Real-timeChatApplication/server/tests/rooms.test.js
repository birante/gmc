import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { Message } from '../src/models/Message.js';
import { seedIfEmpty } from '../src/seed.js';
import { Room } from '../src/models/Room.js';
import { User } from '../src/models/User.js';
import { auth, clearDb, registerUser, startDb, stopDb } from './helpers.js';

const app = createApp();

beforeAll(startDb);
afterEach(clearDb);
afterAll(stopDb);

async function createRoom(token, body = { name: 'Général', description: 'Salon principal' }) {
  return request(app).post('/api/rooms').set(auth(token)).send(body);
}

describe('Salons', () => {
  it('exige une authentification (401)', async () => {
    expect((await request(app).get('/api/rooms')).status).toBe(401);
    expect((await request(app).post('/api/rooms').send({ name: 'X' })).status).toBe(401);
  });

  it('crée un salon dont le créateur est membre', async () => {
    const { token, user } = await registerUser(app);
    const res = await createRoom(token);
    expect(res.status).toBe(201);
    expect(res.body.room).toMatchObject({ name: 'Général', description: 'Salon principal', isMember: true, memberCount: 1 });
    expect(res.body.room.members[0]).toMatchObject({ id: user.id, username: user.username });
  });

  it('valide le nom et refuse les doublons (insensible à la casse)', async () => {
    const { token } = await registerUser(app);
    expect((await createRoom(token, { name: '' })).status).toBe(400);
    expect((await createRoom(token, { name: 'Tech' })).status).toBe(201);
    const dup = await createRoom(token, { name: 'tech' });
    expect(dup.status).toBe(409);
  });

  it('liste les salons avec isMember', async () => {
    const a = await registerUser(app);
    const b = await registerUser(app);
    await createRoom(a.token, { name: 'Tech' });
    const res = await request(app).get('/api/rooms').set(auth(b.token));
    expect(res.status).toBe(200);
    expect(res.body.rooms).toHaveLength(1);
    expect(res.body.rooms[0]).toMatchObject({ name: 'Tech', isMember: false, memberCount: 1 });
  });

  it('rejoint puis quitte un salon (liste des membres mise à jour)', async () => {
    const a = await registerUser(app);
    const b = await registerUser(app);
    const { body } = await createRoom(a.token);
    const id = body.room.id;

    const join = await request(app).post(`/api/rooms/${id}/join`).set(auth(b.token));
    expect(join.status).toBe(200);
    expect(join.body.room.isMember).toBe(true);
    expect(join.body.room.memberCount).toBe(2);

    // Rejoindre deux fois n'ajoute pas de doublon
    const again = await request(app).post(`/api/rooms/${id}/join`).set(auth(b.token));
    expect(again.body.room.memberCount).toBe(2);

    const leave = await request(app).post(`/api/rooms/${id}/leave`).set(auth(b.token));
    expect(leave.status).toBe(200);
    expect(leave.body.room.isMember).toBe(false);
    expect(leave.body.room.memberCount).toBe(1);

    const leaveAgain = await request(app).post(`/api/rooms/${id}/leave`).set(auth(b.token));
    expect(leaveAgain.status).toBe(400);
  });

  it('renvoie 404 pour un salon inexistant ou un id invalide', async () => {
    const { token } = await registerUser(app);
    expect((await request(app).post('/api/rooms/000000000000000000000000/join').set(auth(token))).status).toBe(404);
    expect((await request(app).post('/api/rooms/pas-un-id/join').set(auth(token))).status).toBe(404);
    expect((await request(app).get('/api/rooms/pas-un-id/messages').set(auth(token))).status).toBe(404);
  });
});

describe('Historique des messages', () => {
  it('réservé aux membres (403)', async () => {
    const a = await registerUser(app);
    const b = await registerUser(app);
    const { body } = await createRoom(a.token);
    const res = await request(app).get(`/api/rooms/${body.room.id}/messages`).set(auth(b.token));
    expect(res.status).toBe(403);
  });

  it('pagine avec before et limit (ordre chronologique)', async () => {
    const a = await registerUser(app);
    const { body } = await createRoom(a.token);
    const roomId = body.room.id;
    const base = Date.now() - 100000;
    await Message.insertMany(
      Array.from({ length: 5 }, (_, i) => ({ room: roomId, user: a.user.id, text: `msg ${i}`, createdAt: new Date(base + i * 1000) })),
    );

    const page1 = await request(app).get(`/api/rooms/${roomId}/messages?limit=2`).set(auth(a.token));
    expect(page1.status).toBe(200);
    expect(page1.body.messages.map((m) => m.text)).toEqual(['msg 3', 'msg 4']);
    expect(page1.body.hasMore).toBe(true);
    expect(page1.body.messages[0].user).toMatchObject({ username: a.user.username });

    const before = page1.body.messages[0].createdAt;
    const page2 = await request(app).get(`/api/rooms/${roomId}/messages?limit=2&before=${encodeURIComponent(before)}`).set(auth(a.token));
    expect(page2.body.messages.map((m) => m.text)).toEqual(['msg 1', 'msg 2']);
    expect(page2.body.hasMore).toBe(true);

    const page3 = await request(app)
      .get(`/api/rooms/${roomId}/messages?limit=2&before=${encodeURIComponent(page2.body.messages[0].createdAt)}`)
      .set(auth(a.token));
    expect(page3.body.messages.map((m) => m.text)).toEqual(['msg 0']);
    expect(page3.body.hasMore).toBe(false);
  });

  it('refuse des paramètres de pagination invalides (400)', async () => {
    const a = await registerUser(app);
    const { body } = await createRoom(a.token);
    expect((await request(app).get(`/api/rooms/${body.room.id}/messages?limit=0`).set(auth(a.token))).status).toBe(400);
    expect((await request(app).get(`/api/rooms/${body.room.id}/messages?before=hier`).set(auth(a.token))).status).toBe(400);
  });
});

describe('Seed', () => {
  it('crée les salons et utilisateurs de démo si la base est vide, une seule fois', async () => {
    expect(await seedIfEmpty()).toBe(true);
    expect(await seedIfEmpty()).toBe(false);
    const names = (await Room.find().sort({ createdAt: 1 })).map((r) => r.name);
    expect(names).toEqual(expect.arrayContaining(['Général', 'Tech', 'Détente']));
    expect(await User.countDocuments()).toBe(2);
    const login = await request(app).post('/api/auth/login').send({ email: 'awa@waxtaan.sn', password: 'password123' });
    expect(login.status).toBe(200);
  });
});
