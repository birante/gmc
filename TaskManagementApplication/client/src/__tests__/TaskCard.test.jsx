import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import TaskCard from '../components/TaskCard.jsx';

const base = { id: '1', title: 'Écrire le rapport', description: 'Chapitre 2', priority: 'high', status: 'todo', deadline: null };
const handlers = () => ({ onStatusChange: vi.fn(), onEdit: vi.fn(), onDelete: vi.fn() });

describe('TaskCard', () => {
  it('affiche le titre, la priorité et le statut en français', () => {
    render(<TaskCard task={base} {...handlers()} />);
    expect(screen.getByText('Écrire le rapport')).toBeInTheDocument();
    expect(screen.getByText('Priorité haute')).toBeInTheDocument();
    expect(screen.getByText('À faire')).toBeInTheDocument();
  });

  it('met en évidence une tâche en retard', () => {
    const task = { ...base, deadline: new Date(Date.now() - 2 * 86400000).toISOString() };
    render(<TaskCard task={task} {...handlers()} />);
    expect(screen.getByTestId('task-card')).toHaveClass('overdue');
    expect(screen.getByText(/En retard/)).toBeInTheDocument();
  });

  it('ne marque pas en retard une tâche terminée', () => {
    const task = { ...base, status: 'done', deadline: new Date(Date.now() - 86400000).toISOString() };
    render(<TaskCard task={task} {...handlers()} />);
    expect(screen.getByTestId('task-card')).not.toHaveClass('overdue');
  });

  it('change le statut en un clic et déclenche les actions', async () => {
    const h = handlers();
    render(<TaskCard task={base} {...h} />);
    await userEvent.click(screen.getByRole('button', { name: 'Démarrer' }));
    expect(h.onStatusChange).toHaveBeenCalledWith(base, 'in_progress');
    await userEvent.click(screen.getByRole('button', { name: /comme terminée/ }));
    expect(h.onStatusChange).toHaveBeenCalledWith(base, 'done');
    await userEvent.click(screen.getByRole('button', { name: /Modifier/ }));
    expect(h.onEdit).toHaveBeenCalledWith(base);
    await userEvent.click(screen.getByRole('button', { name: /Supprimer/ }));
    expect(h.onDelete).toHaveBeenCalledWith(base);
  });
});
