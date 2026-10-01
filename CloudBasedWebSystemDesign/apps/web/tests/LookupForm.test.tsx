import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import { LookupForm } from '../src/components/LookupForm';

describe('LookupForm', () => {
  it('submits the normalised card number and phone digits', async () => {
    const onSubmit = vi.fn();
    render(<LookupForm onSubmit={onSubmit} />);
    await userEvent.type(screen.getByLabelText('Card number'), 'vx-demo-2026');
    await userEvent.type(screen.getByLabelText(/Last 4 digits/), '4567');
    await userEvent.click(screen.getByRole('button', { name: /see vaccination schedule/i }));
    expect(onSubmit).toHaveBeenCalledWith('VX-DEMO-2026', '4567');
  });

  it('validates the phone digits before submitting', async () => {
    const onSubmit = vi.fn();
    render(<LookupForm onSubmit={onSubmit} />);
    await userEvent.type(screen.getByLabelText('Card number'), 'VX-DEMO-2026');
    await userEvent.type(screen.getByLabelText(/Last 4 digits/), '12');
    await userEvent.click(screen.getByRole('button'));
    expect(onSubmit).not.toHaveBeenCalled();
    expect(screen.getByRole('alert')).toHaveTextContent('Enter exactly 4 digits.');
  });

  it('disables the button while busy', () => {
    render(<LookupForm onSubmit={vi.fn()} busy />);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
