const TOKEN_KEY = 'booknest_token';

export function getToken() {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setToken(token) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* stockage indisponible */
  }
}

export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export async function request(path, { method = 'GET', body, params } = {}) {
  let url = `/api${path}`;
  if (params) {
    const qs = new URLSearchParams(Object.entries(params).filter(([, v]) => v !== undefined && v !== null && v !== ''));
    if ([...qs].length) url += `?${qs}`;
  }
  const headers = {};
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(url, { method, headers, body: body !== undefined ? JSON.stringify(body) : undefined });
  if (res.status === 204) return null;
  let data = null;
  try {
    data = await res.json();
  } catch {
    data = null;
  }
  if (!res.ok) throw new ApiError(res.status, data?.error || `Erreur ${res.status}`);
  return data;
}

export const api = {
  register: (data) => request('/auth/register', { method: 'POST', body: data }),
  login: (data) => request('/auth/login', { method: 'POST', body: data }),
  me: () => request('/auth/me'),

  feed: (page = 1) => request('/feed', { params: { page } }),
  recommendations: (params) => request('/recommendations', { params }),
  recommendation: (id) => request(`/recommendations/${id}`),
  createRecommendation: (data) => request('/recommendations', { method: 'POST', body: data }),
  deleteRecommendation: (id) => request(`/recommendations/${id}`, { method: 'DELETE' }),
  like: (id) => request(`/recommendations/${id}/like`, { method: 'POST' }),
  unlike: (id) => request(`/recommendations/${id}/like`, { method: 'DELETE' }),
  comments: (id) => request(`/recommendations/${id}/comments`),
  addComment: (id, text) => request(`/recommendations/${id}/comments`, { method: 'POST', body: { text } }),
  deleteComment: (id) => request(`/comments/${id}`, { method: 'DELETE' }),

  searchBooks: (q, type) => request('/books/search', { params: { q, type } }),
  books: (params) => request('/books', { params }),
  genres: () => request('/books/genres'),
  book: (id) => request(`/books/${id}`),
  createBook: (data) => request('/books', { method: 'POST', body: data }),
  updateBook: (id, data) => request(`/books/${id}`, { method: 'PUT', body: data }),
  rateBook: (id, value) => request(`/books/${id}/rate`, { method: 'POST', body: { value } }),

  users: (q) => request('/users', { params: { q } }),
  profile: (username) => request(`/users/${encodeURIComponent(username)}`),
  updateMe: (data) => request('/users/me', { method: 'PATCH', body: data }),
  follow: (id) => request(`/users/${id}/follow`, { method: 'POST' }),
  unfollow: (id) => request(`/users/${id}/follow`, { method: 'DELETE' }),
};
