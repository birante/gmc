import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { vi } from 'vitest';
import Dashboard from '../pages/Dashboard.jsx';

vi.mock('../context/AuthContext.jsx', () => ({ useAuth: () => ({ user: { name: 'Awa Diop' } }) }));

const tasks = [
  { id: 'a', title: 'Tâche A', description: '', priority: 'high', status: 'todo', deadline: null },
  { id: 'b', title: 'Tâche B', description: '', priority: 'low', status: 'done', deadline: null },
];
const stats = { total: 2, byStatus: { todo: 1, in_progress: 0, done: 1 }, overdue: 0, completionRate: 50 };

function mockFetch() {
  return vi.fn(async (url, opts = {}) => {
    const json = (body, status = 200) => ({ ok: status < 400, status, json: async () => body });
    if (url.startsWith('/api/tasks/stats')) return json(stats);
    if (url.startsWith('/api/tasks') && (!opts.method || opts.method === 'GET')) return json({ tasks, count: tasks.length });
    if (opts.method === 'PATCH') return json({ task: { ...tasks[0], status: 'in_progress' } });
    if (opts.method === 'POST') return json({ task: { id: 'c' } }, 201);
    return json({});
  });
}

describe('Dashboard', () => {
  beforeEach(() => { global.fetch = mockFetch(); });

  it('charge et affiche les tâches et la progression', async () => {
    render(<MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}><Dashboard /></MemoryRouter>);
    expect(await screen.findByText('Tâche A')).toBeInTheDocument();
    expect(screen.getByText('Tâche B')).toBeInTheDocument();
    expect(screen.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '50');
    expect(screen.getByText(/Bonjour Awa/)).toBeInTheDocument();
  });

  it('filtre par onglet de statut et change le tri (paramètres envoyés à l’API)', async () => {
    render(<MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}><Dashboard /></MemoryRouter>);
    await screen.findByText('Tâche A');
    await userEvent.click(screen.getByRole('tab', { name: /En cours/ }));
    await waitFor(() => expect(global.fetch).toHaveBeenCalledWith(expect.stringContaining('status=in_progress'), expect.anything()));
    await userEvent.selectOptions(screen.getByLabelText('Trier'), '-priority');
    await waitFor(() => expect(global.fetch).toHaveBeenCalledWith(expect.stringContaining('sort=-priority'), expect.anything()));
  });

  it('change le statut en un clic via PATCH', async () => {
    render(<MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}><Dashboard /></MemoryRouter>);
    const card = (await screen.findByText('Tâche A')).closest('article');
    await userEvent.click(within(card).getByRole('button', { name: 'Démarrer' }));
    await waitFor(() =>
      expect(global.fetch).toHaveBeenCalledWith('/api/tasks/a/status', expect.objectContaining({ method: 'PATCH', body: JSON.stringify({ status: 'in_progress' }) }))
    );
  });

  it('ouvre la modale de création et crée une tâche', async () => {
    render(<MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}><Dashboard /></MemoryRouter>);
    await screen.findByText('Tâche A');
    await userEvent.click(screen.getByRole('button', { name: '+ Nouvelle tâche' }));
    const dialog = screen.getByRole('dialog');
    await userEvent.type(within(dialog).getByLabelText(/Titre/), 'Nouvelle');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Créer la tâche' }));
    await waitFor(() => expect(global.fetch).toHaveBeenCalledWith('/api/tasks', expect.objectContaining({ method: 'POST' })));
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });
});
