import request from 'supertest';
import app from '../src/app.js';

export const api = () => request(app);

let counter = 0;
export async function registerUser(overrides = {}) {
  counter += 1;
  const data = {
    username: `user${counter}`,
    email: `user${counter}@test.dev`,
    password: 'password123',
    ...overrides,
  };
  const res = await api().post('/api/auth/register').send(data);
  if (res.status !== 201) throw new Error(`register failed: ${res.status} ${JSON.stringify(res.body)}`);
  return { token: res.body.token, user: res.body.user, auth: { Authorization: `Bearer ${res.body.token}` } };
}

/** Document de recherche Open Library (format search.json). */
export function olDoc(workId, title, extra = {}) {
  return {
    key: `/works/${workId}`,
    title,
    author_name: extra.authors || ['Auteur Test'],
    subject: extra.subjects || ['Fiction'],
    first_publish_year: extra.year || 2020,
    isbn: extra.isbn || ['1234567890', '9781234567897'],
    cover_i: extra.cover_i === undefined ? 12345 : extra.cover_i,
    number_of_pages_median: 300,
  };
}

export function mockFetchJson(body, { status = 200 } = {}) {
  return async () => ({ ok: status >= 200 && status < 300, status, json: async () => body });
}

/** Simule fetch selon l'URL : routes = [[RegExp, body | (url) => body, status?], ...]. */
export function mockFetchRoutes(routes) {
  return async (url) => {
    const u = String(url);
    for (const [rx, body, status = 200] of routes) {
      if (rx.test(u)) {
        const b = typeof body === 'function' ? body(u) : body;
        return { ok: status >= 200 && status < 300, status, json: async () => b };
      }
    }
    return { ok: false, status: 404, json: async () => ({}) };
  };
}
