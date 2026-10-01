import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { api, startDb, stopDb, resetDb, createUser, createProduct } from './setup.js';
import { Product } from '../src/models/Product.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(resetDb);

const address = { fullName: 'Awa Diop', address: '12 rue Carnot', city: 'Dakar', phone: '771234567' };

describe('Commandes', () => {
  it('401 sans authentification', async () => {
    expect((await api().post('/api/orders').send({})).status).toBe(401);
    expect((await api().get('/api/orders/mine')).status).toBe(401);
  });

  it('crée une commande avec prix recalculés côté serveur et décrémente le stock', async () => {
    const { auth } = await createUser();
    const a = await createProduct({ price: 2000, stock: 5 });
    const b = await createProduct({ price: 3500, stock: 2 });
    const res = await api()
      .post('/api/orders')
      .set(auth)
      .send({
        items: [
          { product: a.id, quantity: 2, price: 1 },
          { product: b.id, quantity: 1 },
          { product: a.id, quantity: 1 }
        ],
        shippingAddress: address,
        total: 1
      });
    expect(res.status).toBe(201);
    expect(res.body.total).toBe(2000 * 3 + 3500);
    expect(res.body.status).toBe('pending');
    expect(res.body.items).toHaveLength(2);
    expect(res.body.items[0]).toMatchObject({ name: a.name, price: 2000, quantity: 3 });
    expect((await Product.findById(a.id)).stock).toBe(2);
    expect((await Product.findById(b.id)).stock).toBe(1);
  });

  it('renvoie 400 si stock insuffisant et ne touche à aucun stock', async () => {
    const { auth } = await createUser();
    const a = await createProduct({ stock: 5 });
    const b = await createProduct({ stock: 1 });
    const res = await api()
      .post('/api/orders')
      .set(auth)
      .send({ items: [{ product: a.id, quantity: 2 }, { product: b.id, quantity: 3 }], shippingAddress: address });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/Stock insuffisant/);
    expect((await Product.findById(a.id)).stock).toBe(5);
    expect((await Product.findById(b.id)).stock).toBe(1);
  });

  it('pas de survente en cas de commandes concurrentes', async () => {
    const { auth } = await createUser();
    const p = await createProduct({ stock: 3 });
    const send = () =>
      api().post('/api/orders').set(auth).send({ items: [{ product: p.id, quantity: 1 }], shippingAddress: address });
    const results = await Promise.all(Array.from({ length: 8 }, send));
    expect(results.filter((r) => r.status === 201)).toHaveLength(3);
    expect(results.filter((r) => r.status === 400)).toHaveLength(5);
    expect((await Product.findById(p.id)).stock).toBe(0);
  });

  it('valide panier vide, adresse et produit inexistant', async () => {
    const { auth } = await createUser();
    expect((await api().post('/api/orders').set(auth).send({ items: [], shippingAddress: address })).status).toBe(400);
    const p = await createProduct();
    expect((await api().post('/api/orders').set(auth).send({ items: [{ product: p.id, quantity: 1 }], shippingAddress: { fullName: 'A' } })).status).toBe(400);
    const ghost = '64b000000000000000000000';
    expect((await api().post('/api/orders').set(auth).send({ items: [{ product: ghost, quantity: 1 }], shippingAddress: address })).status).toBe(400);
  });

  it('paiement simulé, historique et isolation entre clients', async () => {
    const alice = await createUser();
    const bob = await createUser({ email: 'bob@test.sn' });
    const p = await createProduct({ price: 4000 });
    const order = (await api().post('/api/orders').set(alice.auth).send({ items: [{ product: p.id, quantity: 1 }], shippingAddress: address })).body;

    expect((await api().get(`/api/orders/${order.id}`).set(bob.auth)).status).toBe(404);
    expect((await api().post(`/api/orders/${order.id}/pay`).set(bob.auth)).status).toBe(404);

    const paid = await api().post(`/api/orders/${order.id}/pay`).set(alice.auth);
    expect(paid.status).toBe(200);
    expect(paid.body.status).toBe('paid');
    expect(paid.body.paymentRef).toMatch(/^PAY-/);
    expect((await api().post(`/api/orders/${order.id}/pay`).set(alice.auth)).status).toBe(400);

    const mine = await api().get('/api/orders/mine').set(alice.auth);
    expect(mine.status).toBe(200);
    expect(mine.body).toHaveLength(1);
    expect((await api().get('/api/orders/mine').set(bob.auth)).body).toHaveLength(0);
    expect((await api().get(`/api/orders/${order.id}`).set(alice.auth)).body.status).toBe('paid');
    expect((await api().get('/api/orders/64b000000000000000000000').set(alice.auth)).status).toBe(404);
  });
});

describe('Administration des commandes', () => {
  it('403 pour un client sur la liste et le changement de statut', async () => {
    const { auth } = await createUser();
    expect((await api().get('/api/orders').set(auth)).status).toBe(403);
    expect((await api().patch('/api/orders/64b000000000000000000000/status').set(auth).send({ status: 'shipped' })).status).toBe(403);
  });

  it("l'admin liste toutes les commandes et change le statut ; l'annulation restocke", async () => {
    const client = await createUser();
    const admin = await createUser({ email: 'admin@test.sn', role: 'admin' });
    const p = await createProduct({ stock: 4 });
    const order = (await api().post('/api/orders').set(client.auth).send({ items: [{ product: p.id, quantity: 3 }], shippingAddress: address })).body;

    const list = await api().get('/api/orders').set(admin.auth);
    expect(list.status).toBe(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].user.email).toBe('awa@test.sn');

    const shipped = await api().patch(`/api/orders/${order.id}/status`).set(admin.auth).send({ status: 'shipped' });
    expect(shipped.status).toBe(200);
    expect(shipped.body.status).toBe('shipped');

    expect((await api().patch(`/api/orders/${order.id}/status`).set(admin.auth).send({ status: 'lost' })).status).toBe(400);

    const cancelled = await api().patch(`/api/orders/${order.id}/status`).set(admin.auth).send({ status: 'cancelled' });
    expect(cancelled.body.status).toBe('cancelled');
    expect((await Product.findById(p.id)).stock).toBe(4);
    expect((await api().patch(`/api/orders/${order.id}/status`).set(admin.auth).send({ status: 'paid' })).status).toBe(400);
    expect((await api().patch('/api/orders/64b000000000000000000000/status').set(admin.auth).send({ status: 'paid' })).status).toBe(404);
  });
});
