const TOKEN_KEY = 'eventhub_token';
export const UNAUTHORIZED_EVENT = 'eventhub:unauthorized';

export const tokenStore = {
  get() {
    try {
      return localStorage.getItem(TOKEN_KEY);
    } catch {
      return null;
    }
  },
  set(token) {
    try {
      localStorage.setItem(TOKEN_KEY, token);
    } catch {
      /* stockage indisponible */
    }
  },
  clear() {
    try {
      localStorage.removeItem(TOKEN_KEY);
    } catch {
      /* stockage indisponible */
    }
  },
};

export class ApiError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

/** Décode la charge utile d'un JWT (sans vérifier la signature) pour connaître son expiration. */
export function decodeToken(token) {
  try {
    const payload = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(atob(payload));
  } catch {
    return null;
  }
}

export async function apiFetch(path, { method = 'GET', body, signal } = {}) {
  const token = tokenStore.get();
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(`/api${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (err) {
    if (err.name === 'AbortError') throw err;
    throw new ApiError(0, 'Impossible de joindre le serveur');
  }

  if (res.status === 204) return null;
  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    // Jeton expiré ou invalide : déconnexion automatique
    if (res.status === 401 && token) {
      tokenStore.clear();
      window.dispatchEvent(new CustomEvent(UNAUTHORIZED_EVENT, { detail: data.error }));
    }
    throw new ApiError(res.status, data.error || 'Une erreur est survenue', data.details);
  }
  return data;
}

export const api = {
  login: (email, password) => apiFetch('/auth/login', { method: 'POST', body: { email, password } }),
  register: (payload) => apiFetch('/auth/register', { method: 'POST', body: payload }),
  logout: () => apiFetch('/auth/logout', { method: 'POST' }).catch(() => null),
  me: () => apiFetch('/auth/me'),
  updateMe: (payload) => apiFetch('/auth/me', { method: 'PUT', body: payload }),

  listEvents: (params = {}, signal) => {
    const qs = new URLSearchParams(
      Object.entries(params).filter(([, v]) => v !== undefined && v !== null && v !== '')
    ).toString();
    return apiFetch(`/events${qs ? `?${qs}` : ''}`, { signal });
  },
  getEvent: (id) => apiFetch(`/events/${id}`),
  createEvent: (payload) => apiFetch('/events', { method: 'POST', body: payload }),
  updateEvent: (id, payload) => apiFetch(`/events/${id}`, { method: 'PUT', body: payload }),
  deleteEvent: (id) => apiFetch(`/events/${id}`, { method: 'DELETE' }),
  registerToEvent: (id) => apiFetch(`/events/${id}/register`, { method: 'POST' }),
  unregisterFromEvent: (id) => apiFetch(`/events/${id}/register`, { method: 'DELETE' }),

  myEvents: () => apiFetch('/me/events'),
  myRegistrations: () => apiFetch('/me/registrations'),
};
