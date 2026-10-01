import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { io as ioClient } from 'socket.io-client';
import { createServer } from '../src/server.js';
import { Message } from '../src/models/Message.js';
import { auth, clearDb, registerUser, startDb, stopDb } from './helpers.js';

let app;
let server;
let io;
let url;
const sockets = [];

beforeAll(async () => {
  await startDb();
  ({ app, server, io } = createServer());
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  url = `http://127.0.0.1:${server.address().port}`;
});

afterEach(async () => {
  sockets.splice(0).forEach((s) => s.disconnect());
  await clearDb();
});

afterAll(async () => {
  await new Promise((resolve) => io.close(() => resolve()));
  await stopDb();
});

function connect(token) {
  const socket = ioClient(url, { auth: token ? { token } : {}, forceNew: true, reconnection: false });
  sockets.push(socket);
  return socket;
}

const once = (socket, event, predicate = () => true, timeout = 3000) =>
  new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off(event, handler);
      reject(new Error(`timeout en attendant ${event}`));
    }, timeout);
    function handler(data) {
      if (!predicate(data)) return;
      clearTimeout(timer);
      socket.off(event, handler);
      resolve(data);
    }
    socket.on(event, handler);
  });

const connected = (socket) =>
  new Promise((resolve, reject) => {
    socket.once('connect', resolve);
    socket.once('connect_error', reject);
  });

const emitAck = (socket, event, payload) => new Promise((resolve) => socket.emit(event, payload, resolve));

async function setupTwoMembers() {
  const a = await registerUser(app);
  const b = await registerUser(app);
  const res = await request(app).post('/api/rooms').set(auth(a.token)).send({ name: 'Général' });
  const roomId = res.body.room.id;
  await request(app).post(`/api/rooms/${roomId}/join`).set(auth(b.token));
  const sa = connect(a.token);
  const sb = connect(b.token);
  await Promise.all([connected(sa), connected(sb)]);
  return { a, b, roomId, sa, sb };
}

describe('Socket.IO — authentification', () => {
  it('refuse une connexion sans jeton', async () => {
    const s = connect();
    await expect(connected(s)).rejects.toThrow('Non authentifié');
  });

  it('refuse une connexion avec un jeton invalide', async () => {
    const s = connect('jeton.invalide');
    await expect(connected(s)).rejects.toThrow('Non authentifié');
  });

  it('accepte une connexion avec un jeton valide', async () => {
    const { token } = await registerUser(app);
    const s = connect(token);
    await connected(s);
    expect(s.connected).toBe(true);
  });
});

describe('Socket.IO — salons et messages', () => {
  it('refuse room:join à un non-membre', async () => {
    const a = await registerUser(app);
    const b = await registerUser(app);
    const res = await request(app).post('/api/rooms').set(auth(a.token)).send({ name: 'Privé' });
    const sb = connect(b.token);
    await connected(sb);
    const ack = await emitAck(sb, 'room:join', { roomId: res.body.room.id });
    expect(ack.error).toMatch(/membre/);
  });

  it('diffuse la présence (room:users) aux membres connectés', async () => {
    const { a, b, roomId, sa, sb } = await setupTwoMembers();
    await emitAck(sa, 'room:join', { roomId });
    const both = once(sa, 'room:users', (d) => d.users.length === 2);
    const ack = await emitAck(sb, 'room:join', { roomId });
    expect(ack.ok).toBe(true);
    const presence = await both;
    expect(presence.users.map((u) => u.username).sort()).toEqual([a.user.username, b.user.username].sort());

    const afterLeave = once(sa, 'room:users', (d) => d.users.length === 1);
    sb.disconnect();
    const left = await afterLeave;
    expect(left.users[0].username).toBe(a.user.username);
  });

  it('envoie un message entre deux clients et le persiste', async () => {
    const { a, roomId, sa, sb } = await setupTwoMembers();
    await emitAck(sa, 'room:join', { roomId });
    await emitAck(sb, 'room:join', { roomId });

    const received = once(sb, 'message:new');
    const ack = await emitAck(sa, 'message:send', { roomId, text: '  Na nga def ?  ' });
    expect(ack.ok).toBe(true);
    const msg = await received;
    expect(msg).toMatchObject({ room: roomId, text: 'Na nga def ?', user: { username: a.user.username } });
    expect(new Date(msg.createdAt).getTime()).not.toBeNaN();

    const saved = await Message.find({ room: roomId });
    expect(saved).toHaveLength(1);
    const history = await request(app).get(`/api/rooms/${roomId}/messages`).set(auth(a.token));
    expect(history.body.messages[0].text).toBe('Na nga def ?');
  });

  it('valide les messages (vide, trop long, salon non rejoint)', async () => {
    const { roomId, sa } = await setupTwoMembers();
    expect((await emitAck(sa, 'message:send', { roomId, text: '   ' })).error).toBeTruthy();
    expect((await emitAck(sa, 'message:send', { roomId, text: 'x'.repeat(2001) })).error).toBeTruthy();
    expect((await emitAck(sa, 'message:send', { roomId: '000000000000000000000000', text: 'hello' })).error).toBe('Salon introuvable');
    expect(await Message.countDocuments()).toBe(0);
  });

  it('relaie typing:start / typing:stop aux autres membres', async () => {
    const { a, roomId, sa, sb } = await setupTwoMembers();
    await emitAck(sa, 'room:join', { roomId });
    await emitAck(sb, 'room:join', { roomId });

    const start = once(sb, 'typing', (d) => d.isTyping === true);
    sa.emit('typing:start', { roomId });
    expect(await start).toMatchObject({ roomId, isTyping: true, user: { username: a.user.username } });

    const stop = once(sb, 'typing', (d) => d.isTyping === false);
    sa.emit('typing:stop', { roomId });
    expect(await stop).toMatchObject({ roomId, isTyping: false });
  });

  it('ne reçoit plus les messages après room:leave', async () => {
    const { roomId, sa, sb } = await setupTwoMembers();
    await emitAck(sa, 'room:join', { roomId });
    await emitAck(sb, 'room:join', { roomId });
    await emitAck(sb, 'room:leave', { roomId });

    let got = false;
    sb.on('message:new', () => {
      got = true;
    });
    const own = once(sa, 'message:new');
    await emitAck(sa, 'message:send', { roomId, text: 'test' });
    await own;
    await new Promise((r) => setTimeout(r, 100));
    expect(got).toBe(false);
  });
});
