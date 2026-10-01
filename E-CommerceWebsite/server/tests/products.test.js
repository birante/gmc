import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { api, startDb, stopDb, resetDb, createUser, createProduct } from './setup.js';
import { Product } from '../src/models/Product.js';
import { User } from '../src/models/User.js';
import { seedIfEmpty, demoProducts } from '../src/seed.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(resetDb);

describe('Catalogue public', () => {
  beforeEach(async () => {
    await createProduct({ name: 'Robe wax', slug: 'robe-wax', category: 'Mode', price: 15000 });
    await createProduct({ name: 'Sandales cuir', slug: 'sandales-cuir', category: 'Mode', price: 8000 });
    await createProduct({ name: 'Miel pur', slug: 'miel-pur', category: 'Épicerie', price: 5000, description: 'Miel de Casamance' });
  });

  it('liste paginée', async () => {
    const res = await api().get('/api/products?limit=2&page=1');
    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(2);
    expect(res.body.total).toBe(3);
    expect(res.body.pages).toBe(2);
    const p2 = await api().get('/api/products?limit=2&page=2');
    expect(p2.body.items).toHaveLength(1);
  });

  it('recherche texte (nom ou description)', async () => {
    const res = await api().get('/api/products?search=casamance');
    expect(res.body.items.map((p) => p.slug)).toEqual(['miel-pur']);
  });

  it('filtre catégorie et prix', async () => {
    const res = await api().get('/api/products?category=Mode&minPrice=9000');
    expect(res.body.items.map((p) => p.slug)).toEqual(['robe-wax']);
    const res2 = await api().get('/api/products?maxPrice=8000');
    expect(res2.body.total).toBe(2);
  });

  it('tri par prix', async () => {
    const asc = await api().get('/api/products?sort=price_asc');
    expect(asc.body.items.map((p) => p.price)).toEqual([5000, 8000, 15000]);
    const desc = await api().get('/api/products?sort=price_desc');
    expect(desc.body.items.map((p) => p.price)).toEqual([15000, 8000, 5000]);
  });

  it('paramètre de tri invalide -> 400', async () => {
    expect((await api().get('/api/products?sort=bogus')).status).toBe(400);
  });

  it('détail par slug et 404', async () => {
    const res = await api().get('/api/products/robe-wax');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Robe wax');
    expect((await api().get('/api/products/inexistant')).status).toBe(404);
  });

  it('liste des catégories avec comptage', async () => {
    const res = await api().get('/api/categories');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([
      { name: 'Mode', count: 2 },
      { name: 'Épicerie', count: 1 }
    ]);
  });
});

describe('Administration des produits', () => {
  const body = { name: 'Thé vert', price: 2500, category: 'Épicerie', stock: 5, description: 'Thé de Chine' };

  it('401 sans jeton, 403 pour un client', async () => {
    expect((await api().post('/api/products').send(body)).status).toBe(401);
    const { auth } = await createUser();
    expect((await api().post('/api/products').set(auth).send(body)).status).toBe(403);
    const p = await createProduct();
    expect((await api().put(`/api/products/${p.id}`).set(auth).send({ price: 1 })).status).toBe(403);
    expect((await api().delete(`/api/products/${p.id}`).set(auth)).status).toBe(403);
  });

  it('CRUD complet pour un admin', async () => {
    const { auth } = await createUser({ email: 'admin@test.sn', role: 'admin' });
    const created = await api().post('/api/products').set(auth).send(body);
    expect(created.status).toBe(201);
    expect(created.body.slug).toBe('the-vert');
    expect(created.body.imageUrl).toContain('picsum.photos/seed/the-vert');

    const dup = await api().post('/api/products').set(auth).send(body);
    expect(dup.body.slug).toBe('the-vert-2');

    const upd = await api().put(`/api/products/${created.body.id}`).set(auth).send({ price: 3000, stock: 9 });
    expect(upd.status).toBe(200);
    expect(upd.body).toMatchObject({ price: 3000, stock: 9 });

    const del = await api().delete(`/api/products/${created.body.id}`).set(auth);
    expect(del.status).toBe(204);
    expect((await api().get('/api/products/the-vert')).status).toBe(404);
    expect((await api().delete(`/api/products/${created.body.id}`).set(auth)).status).toBe(404);
  });

  it('valide prix entier et stock positif', async () => {
    const { auth } = await createUser({ email: 'admin@test.sn', role: 'admin' });
    expect((await api().post('/api/products').set(auth).send({ ...body, price: 10.5 })).status).toBe(400);
    expect((await api().post('/api/products').set(auth).send({ ...body, stock: -1 })).status).toBe(400);
  });
});

describe('Seed', () => {
  it('insère produits, admin et client démo seulement si vide', async () => {
    expect(await seedIfEmpty({ log: false })).toBe(true);
    expect(await Product.countDocuments()).toBe(demoProducts.length);
    expect(await User.findOne({ email: 'admin@boutik.sn' })).toMatchObject({ role: 'admin' });
    expect(await User.findOne({ email: 'demo@boutik.sn' })).toMatchObject({ role: 'client' });
    expect(await seedIfEmpty({ log: false })).toBe(false);
    expect(await Product.countDocuments()).toBe(demoProducts.length);
    const login = await api().post('/api/auth/login').send({ email: 'admin@boutik.sn', password: 'admin12345' });
    expect(login.status).toBe(200);
  });
});
