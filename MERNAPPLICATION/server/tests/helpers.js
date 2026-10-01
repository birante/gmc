import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import request from 'supertest';
import app from '../src/app.js';

let mongod;

export async function startDb() {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
}

export async function stopDb() {
  await mongoose.disconnect();
  if (mongod) await mongod.stop();
}

export async function clearDb() {
  const collections = await mongoose.connection.db.collections();
  await Promise.all(collections.map((c) => c.deleteMany({})));
}

export const api = () => request(app);

let counter = 0;
export async function createUser(overrides = {}) {
  counter += 1;
  const payload = {
    name: `Utilisateur ${counter}`,
    email: `user${counter}@test.dev`,
    password: 'password123',
    ...overrides,
  };
  const res = await api().post('/api/auth/register').send(payload);
  if (res.status !== 201) throw new Error(`register failed: ${res.status} ${JSON.stringify(res.body)}`);
  return { token: res.body.token, user: res.body.user, auth: { Authorization: `Bearer ${res.body.token}` } };
}

export const futureDate = (days = 7) => new Date(Date.now() + days * 86400000).toISOString();
export const pastDate = (days = 7) => new Date(Date.now() - days * 86400000).toISOString();

export const eventPayload = (overrides = {}) => ({
  title: 'Meetup React',
  description: 'Une super soirée autour de React et Vite.',
  date: futureDate(),
  location: 'Dakar',
  category: 'Tech',
  capacity: 2,
  imageUrl: 'https://picsum.photos/seed/test/800/400',
  ...overrides,
});

export async function createEvent(auth, overrides = {}) {
  const res = await api().post('/api/events').set(auth).send(eventPayload(overrides));
  if (res.status !== 201) throw new Error(`create failed: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.event;
}
