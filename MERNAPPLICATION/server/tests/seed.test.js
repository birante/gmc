import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startDb, stopDb, clearDb, api } from './helpers.js';
import { seedIfEmpty } from '../src/seed.js';

beforeAll(async () => { await startDb(); await clearDb(); });
afterAll(stopDb);

describe('Seed', () => {
  it('peuple une base vide une seule fois', async () => {
    const first = await seedIfEmpty();
    expect(first).toEqual({ users: 2, events: 8 });
    expect(await seedIfEmpty()).toBeNull();

    const login = await api().post('/api/auth/login').send({ email: 'aminata@eventhub.dev', password: 'password123' });
    expect(login.status).toBe(200);
    const up = await api().get('/api/events?when=upcoming');
    const past = await api().get('/api/events?when=past');
    expect(up.body.total).toBe(6);
    expect(past.body.total).toBe(2);
  });
});
