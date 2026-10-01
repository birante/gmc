import { render, screen } from '@testing-library/react';
import { StatusBadge } from '../src/components/StatusBadge';

describe('StatusBadge', () => {
  it.each([
    ['ADMINISTERED', 'Given'],
    ['DUE', 'Due'],
    ['OVERDUE', 'Overdue'],
    ['UPCOMING', 'Upcoming'],
  ] as const)('renders %s as "%s"', (status, label) => {
    render(<StatusBadge status={status} />);
    expect(screen.getByText(label)).toBeInTheDocument();
  });

  it('uses a red style for overdue doses', () => {
    render(<StatusBadge status="OVERDUE" />);
    expect(screen.getByText('Overdue').className).toContain('bg-red-100');
  });
});
