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
export async function registerUser(overrides = {}) {
  counter += 1;
  const body = { name: `User ${counter}`, email: `user${counter}@test.sn`, password: 'secret123', ...overrides };
  const res = await api().post('/api/auth/register').send(body);
  return { token: res.body.token, user: res.body.user, body, res };
}

export const auth = (token) => ({ Authorization: `Bearer ${token}` });
