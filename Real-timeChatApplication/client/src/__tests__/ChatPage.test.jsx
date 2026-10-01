import { afterEach, describe, expect, it, vi } from 'vitest';
import { act, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const me = { id: 'u1', username: 'awa', email: 'awa@waxtaan.sn', avatarColor: '#e76f51' };
const moussa = { id: 'u2', username: 'moussa', avatarColor: '#3a86ff' };

// Faux socket minimal
const handlers = {};
const fakeSocket = {
  on: (e, h) => { (handlers[e] ||= new Set()).add(h); },
  off: (e, h) => handlers[e]?.delete(h),
  emit: vi.fn((event, payload, ack) => {
    if (event === 'room:join') ack?.({ ok: true, users: [me] });
  }),
  timeout: () => ({
    emit: (event, payload, ack) =>
      ack(null, { ok: true, message: { id: 'm9', room: payload.roomId, text: payload.text, createdAt: new Date().toISOString(), user: me } }),
  }),
};
const fire = (e, data) => act(() => handlers[e]?.forEach((h) => h(data)));

vi.mock('../context/AuthContext.jsx', () => ({ useAuth: () => ({ user: me, logout: vi.fn() }) }));
vi.mock('../context/SocketContext.jsx', () => ({ useSocket: () => ({ socket: fakeSocket, connected: true }) }));

const { default: ChatPage } = await import('../pages/ChatPage.jsx');

const rooms = [
  { id: 'r1', name: 'Général', description: 'Discussions', members: [me, moussa], memberCount: 2, isMember: true },
  { id: 'r2', name: 'Tech', description: '', members: [moussa], memberCount: 1, isMember: false },
];
const ok = (body) => ({ ok: true, status: 200, json: async () => body });

afterEach(() => vi.unstubAllGlobals());

describe('ChatPage', () => {
  it('affiche le salon, l’historique, les messages temps réel et l’indicateur de saisie', async () => {
    vi.stubGlobal('fetch', vi.fn(async (url) => {
      if (url === '/api/rooms') return ok({ rooms });
      if (url.startsWith('/api/rooms/r1/messages'))
        return ok({ hasMore: false, messages: [{ id: 'm1', room: 'r1', text: 'Salut Awa', createdAt: new Date().toISOString(), user: moussa }] });
      throw new Error(url);
    }));
    render(
      <MemoryRouter initialEntries={['/salons/r1']}>
        <Routes><Route path="/salons/:roomId" element={<ChatPage />} /></Routes>
      </MemoryRouter>,
    );
    expect(await screen.findByText('Salut Awa')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: '# Général' })).toBeInTheDocument();
    expect(fakeSocket.emit).toHaveBeenCalledWith('room:join', { roomId: 'r1' }, expect.any(Function));
    expect(screen.getByText('En ligne — 1')).toBeInTheDocument();

    fire('typing', { roomId: 'r1', user: moussa, isTyping: true });
    expect(screen.getByText("moussa est en train d'écrire…")).toBeInTheDocument();

    fire('message:new', { id: 'm2', room: 'r1', text: 'Nouveau message', createdAt: new Date().toISOString(), user: moussa });
    expect(screen.getByText('Nouveau message')).toBeInTheDocument();

    await userEvent.type(screen.getByLabelText('Message'), 'Je réponds{Enter}');
    expect(await screen.findByText('Je réponds')).toBeInTheDocument();
  });

  it('propose de rejoindre un salon dont on n’est pas membre', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ok({ rooms })));
    render(
      <MemoryRouter initialEntries={['/salons/r2']}>
        <Routes><Route path="/salons/:roomId" element={<ChatPage />} /></Routes>
      </MemoryRouter>,
    );
    expect(await screen.findByRole('button', { name: 'Rejoindre le salon' })).toBeInTheDocument();
  });
});
