import { vi } from 'vitest';
import { apiFetch, tokenStore, UNAUTHORIZED_EVENT, decodeToken } from '../api/client.js';

const jsonResponse = (status, body) => ({ status, ok: status < 400, json: async () => body });

describe('apiFetch', () => {
  afterEach(() => vi.restoreAllMocks());

  it('ajoute le jeton Bearer', async () => {
    tokenStore.set('abc');
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse(200, { ok: true }));
    await apiFetch('/auth/me');
    expect(fetchMock.mock.calls[0][1].headers.Authorization).toBe('Bearer abc');
  });

  it('déconnecte automatiquement sur 401 (session expirée)', async () => {
    tokenStore.set('expired');
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse(401, { error: 'Session expirée' }));
    const listener = vi.fn();
    window.addEventListener(UNAUTHORIZED_EVENT, listener);
    await expect(apiFetch('/auth/me')).rejects.toMatchObject({ status: 401, message: 'Session expirée' });
    expect(listener).toHaveBeenCalledOnce();
    expect(tokenStore.get()).toBeNull();
    window.removeEventListener(UNAUTHORIZED_EVENT, listener);
  });

  it('décode la charge utile du JWT', () => {
    const payload = btoa(JSON.stringify({ sub: '1', exp: 123 }));
    expect(decodeToken(`h.${payload}.s`)).toMatchObject({ exp: 123 });
    expect(decodeToken('invalide')).toBeNull();
  });
});
