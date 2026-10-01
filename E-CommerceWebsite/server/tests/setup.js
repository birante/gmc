import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { User } from '../src/models/User.js';
import { Product } from '../src/models/Product.js';
import { Order } from '../src/models/Order.js';
import { signToken } from '../src/utils/token.js';

let mongod;
export const app = createApp();
export const api = () => request(app);

export async function startDb() {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
}

export async function stopDb() {
  await mongoose.disconnect();
  if (mongod) await mongod.stop();
}

export async function resetDb() {
  await Promise.all([User.deleteMany({}), Product.deleteMany({}), Order.deleteMany({})]);
}

export async function createUser({ name = 'Awa', email = 'awa@test.sn', password = 'secret123', role = 'client' } = {}) {
  const user = await User.create({ name, email, role, passwordHash: await User.hashPassword(password) });
  return { user, token: signToken(user), auth: { Authorization: `Bearer ${signToken(user)}` } };
}

export async function createProduct(overrides = {}) {
  const n = Math.random().toString(36).slice(2, 8);
  return Product.create({
    name: `Produit ${n}`,
    slug: `produit-${n}`,
    description: 'Description',
    price: 1000,
    category: 'Divers',
    stock: 10,
    ...overrides
  });
}
