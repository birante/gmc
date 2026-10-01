import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext.jsx';

/** Simule fetch : routes = { 'GET /api/auth/me': body | (url, init) => body } */
export function mockApi(routes) {
  const fn = vi.fn(async (url, init = {}) => {
    const key = `${init.method || 'GET'} ${String(url).split('?')[0]}`;
    const handler = routes[key];
    if (!handler) return { ok: false, status: 404, json: async () => ({ error: `non mocké: ${key}` }) };
    const result = typeof handler === 'function' ? handler(url, init) : handler;
    const { status = 200, body = result } = result?.__status ? { status: result.__status, body: result.body } : {};
    return { ok: status < 400, status, json: async () => body };
  });
  vi.stubGlobal('fetch', fn);
  return fn;
}

export function renderWithProviders(ui, { route = '/' } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]} future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AuthProvider>{ui}</AuthProvider>
    </MemoryRouter>
  );
}
