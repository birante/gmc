const TOKEN_KEY = 'taskflow_token';

export const tokenStore = {
  get: () => {
    try { return localStorage.getItem(TOKEN_KEY); } catch { return null; }
  },
  set: (t) => {
    try { localStorage.setItem(TOKEN_KEY, t); } catch { /* ignore */ }
  },
  clear: () => {
    try { localStorage.removeItem(TOKEN_KEY); } catch { /* ignore */ }
  },
};

export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

let onUnauthorized = () => {};
export const setUnauthorizedHandler = (fn) => { onUnauthorized = fn; };

export async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const token = tokenStore.get();
  if (auth && token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`/api${path}`, { method, headers, body: body !== undefined ? JSON.stringify(body) : undefined });
  if (res.status === 204) return null;
  let data = null;
  try { data = await res.json(); } catch { /* corps vide */ }
  if (!res.ok) {
    if (res.status === 401 && auth) onUnauthorized();
    throw new ApiError(res.status, data?.error || 'Une erreur est survenue');
  }
  return data;
}

export const authApi = {
  register: (payload) => request('/auth/register', { method: 'POST', body: payload, auth: false }),
  login: (payload) => request('/auth/login', { method: 'POST', body: payload, auth: false }),
  me: () => request('/auth/me'),
};

export const tasksApi = {
  list: ({ status, search, sort } = {}) => {
    const qs = new URLSearchParams();
    if (status) qs.set('status', status);
    if (search) qs.set('search', search);
    if (sort) qs.set('sort', sort);
    const q = qs.toString();
    return request(`/tasks${q ? `?${q}` : ''}`);
  },
  stats: () => request('/tasks/stats'),
  create: (payload) => request('/tasks', { method: 'POST', body: payload }),
  update: (id, payload) => request(`/tasks/${id}`, { method: 'PUT', body: payload }),
  setStatus: (id, status) => request(`/tasks/${id}/status`, { method: 'PATCH', body: { status } }),
  remove: (id) => request(`/tasks/${id}`, { method: 'DELETE' }),
};
