import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import type { Dose } from '../src/api/types';
import { DoseTable } from '../src/components/DoseTable';

const dose = (overrides: Partial<Dose>): Dose => ({
  id: 'd1',
  vaccine: { id: 'v1', code: 'PENTA-1', name: 'Pentavalent 1', antigen: 'Penta', doseNumber: 1 },
  scheduledDate: '2026-10-05',
  administeredDate: null,
  administeredBy: null,
  lotNumber: null,
  notes: null,
  status: 'DUE',
  ...overrides,
});

describe('DoseTable', () => {
  it('offers "Record dose" only for doses not yet given', async () => {
    const onAdminister = vi.fn();
    render(
      <DoseTable
        doses={[dose({}), dose({ id: 'd2', status: 'ADMINISTERED', scheduledDate: '2026-08-30', administeredDate: '2026-09-01', vaccine: { id: 'v2', code: 'BCG', name: 'BCG', antigen: 'BCG', doseNumber: 1 } })]}
        onAdminister={onAdminister}
      />,
    );
    const buttons = screen.getAllByRole('button', { name: 'Record dose' });
    expect(buttons).toHaveLength(1);
    await userEvent.click(buttons[0]!);
    expect(onAdminister).toHaveBeenCalledWith(expect.objectContaining({ id: 'd1' }));
    expect(screen.getByText('05/10/2026')).toBeInTheDocument();
    expect(screen.getByText('01/09/2026')).toBeInTheDocument();
  });
});
