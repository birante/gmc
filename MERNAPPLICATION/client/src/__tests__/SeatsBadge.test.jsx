import { render, screen } from '@testing-library/react';
import SeatsBadge, { seatsStatus } from '../components/SeatsBadge.jsx';

describe('SeatsBadge', () => {
  it('affiche le nombre de places restantes', () => {
    render(<SeatsBadge seatsLeft={42} capacity={60} />);
    expect(screen.getByTestId('seats-badge')).toHaveTextContent('42 places restantes');
    expect(screen.getByTestId('seats-badge')).toHaveClass('badge-success');
  });

  it('alerte quand il reste peu de places', () => {
    render(<SeatsBadge seatsLeft={1} capacity={20} />);
    expect(screen.getByTestId('seats-badge')).toHaveTextContent('Plus que 1 place !');
    expect(screen.getByTestId('seats-badge')).toHaveClass('badge-warning');
  });

  it('indique Complet et Terminé', () => {
    expect(seatsStatus({ seatsLeft: 0, capacity: 10 }).label).toBe('Complet');
    expect(seatsStatus({ seatsLeft: 5, capacity: 10, isPast: true }).label).toBe('Terminé');
  });
});
