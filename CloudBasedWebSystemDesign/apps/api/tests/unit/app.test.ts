import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { createApp } from '../../src/app.js';

// These HTTP-level tests exercise middleware only (no query reaches the database).
const db = new PrismaClient({ datasourceUrl: 'postgresql://unused:unused@127.0.0.1:1/unused' });
const app = createApp({ db });

afterAll(() => db.$disconnect());

describe('HTTP pipeline (no database)', () => {
  it('sets security headers and hides the framework', async () => {
    const res = await request(app).get('/api/openapi.json');
    expect(res.status).toBe(200);
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['content-security-policy']).toBeDefined();
    expect(res.body.openapi).toBe('3.1.0');
  });

  it('requires a token on protected routes', async () => {
    const res = await request(app).get('/api/patients');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('rejects forged tokens', async () => {
    const res = await request(app).get('/api/patients').set('Authorization', 'Bearer not-a-jwt');
    expect(res.status).toBe(401);
  });

  it('validates request bodies with field-level details', async () => {
    const res = await request(app).post('/api/auth/login').send({ email: 'not-an-email' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.details.map((d: { path: string }) => d.path)).toEqual(expect.arrayContaining(['email', 'password']));
  });

  it('rejects malformed JSON', async () => {
    const res = await request(app).post('/api/auth/login').set('Content-Type', 'application/json').send('{"email":');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('BAD_REQUEST');
  });

  it('validates public lookup input', async () => {
    const res = await request(app).post('/api/public/lookup').send({ referenceCode: 'VX-DEMO-2026', phoneLast4: '12a4' });
    expect(res.status).toBe(400);
  });

  it('returns JSON 404 for unknown API routes', async () => {
    const res = await request(app).get('/api/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('answers CORS preflight for allowed origins only', async () => {
    const ok = await request(app).options('/api/patients').set('Origin', 'http://localhost:5173').set('Access-Control-Request-Method', 'GET');
    expect(ok.headers['access-control-allow-origin']).toBe('http://localhost:5173');
    const ko = await request(app).options('/api/patients').set('Origin', 'https://evil.example').set('Access-Control-Request-Method', 'GET');
    expect(ko.headers['access-control-allow-origin']).toBeUndefined();
  });
});
