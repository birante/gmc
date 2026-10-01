import { render, screen } from '@testing-library/react';
import StatsPanel from '../components/StatsPanel.jsx';
import { formatDeadline, fromDateInput, toDateInput } from '../utils/labels.js';

describe('StatsPanel', () => {
  it('affiche la barre de progression et les compteurs', () => {
    render(<StatsPanel stats={{ total: 4, byStatus: { todo: 1, in_progress: 1, done: 2 }, overdue: 1, completionRate: 50 }} />);
    expect(screen.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '50');
    expect(screen.getByText('50%')).toBeInTheDocument();
    expect(screen.getByText('2 tâches terminées sur 4')).toBeInTheDocument();
    expect(screen.getByText('En retard').previousSibling).toHaveTextContent('1');
  });
});

describe('utilitaires de date', () => {
  it('aller-retour date locale <-> input', () => {
    expect(toDateInput(fromDateInput('2026-03-15'))).toBe('2026-03-15');
    expect(fromDateInput('')).toBeNull();
  });
  it('formate les échéances relatives', () => {
    const now = new Date(2026, 5, 10, 12);
    expect(formatDeadline(new Date(2026, 5, 10, 18).toISOString(), now)).toMatch(/^Aujourd’hui/);
    expect(formatDeadline(new Date(2026, 5, 11).toISOString(), now)).toMatch(/^Demain/);
    expect(formatDeadline(new Date(2026, 5, 7).toISOString(), now)).toMatch(/^Il y a 3 j/);
  });
});
