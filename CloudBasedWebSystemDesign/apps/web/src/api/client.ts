import type {
  Clinic, DashboardStats, Paginated, PatientDetail, PatientSummary, PublicLookup, ReminderMessage, User, WorklistItem,
} from './types';

const BASE_URL = (import.meta.env.VITE_API_URL ?? '').replace(/\/$/, '');
const TOKEN_KEY = 'vaxtrack.token';

export class ApiError extends Error {
  constructor(public status: number, message: string, public details?: Array<{ path: string; message: string }>) {
    super(message);
  }
}

export const tokenStore = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (token: string) => localStorage.setItem(TOKEN_KEY, token),
  clear: () => localStorage.removeItem(TOKEN_KEY),
};

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = tokenStore.get();
  const res = await fetch(`${BASE_URL}/api${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });
  if (res.status === 204) return undefined as T;
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401 && token) {
      tokenStore.clear();
      window.dispatchEvent(new Event('vaxtrack:logout'));
    }
    throw new ApiError(res.status, body?.error?.message ?? res.statusText, body?.error?.details);
  }
  return body as T;
}

const qs = (params: Record<string, string | number | undefined>) => {
  const s = new URLSearchParams(
    Object.entries(params).filter(([, v]) => v !== undefined && v !== '') as [string, string][],
  ).toString();
  return s ? `?${s}` : '';
};

export const api = {
  login: (email: string, password: string) =>
    request<{ data: { token: string; user: User } }>('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  me: () => request<{ data: User }>('/auth/me'),

  stats: (clinicId?: string) => request<{ data: DashboardStats }>(`/dashboard/stats${qs({ clinicId })}`),

  patients: (params: { search?: string; page?: number; clinicId?: string }) =>
    request<Paginated<PatientSummary>>(`/patients${qs(params)}`),
  patient: (id: string) => request<{ data: PatientDetail }>(`/patients/${id}`),
  createPatient: (input: Record<string, unknown>) =>
    request<{ data: PatientDetail }>('/patients', { method: 'POST', body: JSON.stringify(input) }),

  administer: (id: string, input: { administeredDate?: string; lotNumber?: string }) =>
    request(`/immunizations/${id}/administer`, { method: 'POST', body: JSON.stringify(input) }),
  revert: (id: string) => request(`/immunizations/${id}/revert`, { method: 'POST' }),
  worklist: (status: 'DUE' | 'OVERDUE', clinicId?: string) =>
    request<{ data: WorklistItem[] }>(`/immunizations/worklist${qs({ status, clinicId })}`),

  reminderPreview: () => request<{ data: ReminderMessage[] }>('/reminders/preview'),
  sendReminders: () => request<{ data: { candidates: number; sent: number; failed: string[] } }>('/reminders/send', { method: 'POST' }),

  clinics: () => request<{ data: Clinic[] }>('/clinics'),
  createClinic: (input: Omit<Clinic, 'id'>) => request<{ data: Clinic }>('/clinics', { method: 'POST', body: JSON.stringify(input) }),
  users: () => request<{ data: User[] }>('/users'),
  createUser: (input: Record<string, unknown>) => request<{ data: User }>('/users', { method: 'POST', body: JSON.stringify(input) }),
  updateUser: (id: string, input: Record<string, unknown>) =>
    request<{ data: User }>(`/users/${id}`, { method: 'PATCH', body: JSON.stringify(input) }),

  publicLookup: (referenceCode: string, phoneLast4: string) =>
    request<{ data: PublicLookup }>('/public/lookup', { method: 'POST', body: JSON.stringify({ referenceCode, phoneLast4 }) }),
};
