import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import TaskForm from '../components/TaskForm.jsx';

describe('TaskForm', () => {
  it('refuse un titre vide', async () => {
    const onSubmit = vi.fn();
    render(<TaskForm onSubmit={onSubmit} onCancel={() => {}} />);
    await userEvent.click(screen.getByRole('button', { name: 'Créer la tâche' }));
    expect(screen.getByRole('alert')).toHaveTextContent('Le titre est requis');
    expect(onSubmit).not.toHaveBeenCalled();
  });

  it('soumet les valeurs saisies', async () => {
    const onSubmit = vi.fn().mockResolvedValue();
    render(<TaskForm onSubmit={onSubmit} onCancel={() => {}} />);
    await userEvent.type(screen.getByLabelText(/Titre/), '  Nouvelle tâche ');
    await userEvent.selectOptions(screen.getByLabelText('Priorité'), 'high');
    await userEvent.click(screen.getByRole('button', { name: 'Créer la tâche' }));
    expect(onSubmit).toHaveBeenCalledWith(expect.objectContaining({ title: 'Nouvelle tâche', priority: 'high', status: 'todo', deadline: null }));
  });

  it('pré-remplit le formulaire en édition', () => {
    const initial = { id: '1', title: 'Existante', description: 'd', priority: 'low', status: 'in_progress', deadline: '2026-12-24T22:59:00.000Z' };
    render(<TaskForm initial={initial} onSubmit={vi.fn()} onCancel={() => {}} />);
    expect(screen.getByLabelText(/Titre/)).toHaveValue('Existante');
    expect(screen.getByLabelText('Statut')).toHaveValue('in_progress');
    expect(screen.getByRole('button', { name: 'Enregistrer' })).toBeInTheDocument();
  });
});
