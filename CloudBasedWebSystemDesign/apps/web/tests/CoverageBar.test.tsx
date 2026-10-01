import { render, screen } from '@testing-library/react';
import { CoverageBar } from '../src/components/CoverageBar';

describe('CoverageBar', () => {
  it('shows the percentage and the numerator/denominator', () => {
    render(<CoverageBar label="PENTA-3" value={87.5} administered={35} eligible={40} />);
    expect(screen.getByText('PENTA-3')).toBeInTheDocument();
    expect(screen.getByText(/87\.5%/)).toBeInTheDocument();
    expect(screen.getByText('(35/40)')).toBeInTheDocument();
    expect(screen.getByRole('progressbar', { name: 'PENTA-3 coverage' })).toHaveAttribute('aria-valuenow', '87.5');
  });

  it('is green when the target is reached and red when far below', () => {
    const { container, rerender } = render(<CoverageBar label="BCG" value={95} administered={95} eligible={100} />);
    expect(container.querySelector('.bg-emerald-500')).not.toBeNull();
    rerender(<CoverageBar label="BCG" value={50} administered={50} eligible={100} />);
    expect(container.querySelector('.bg-red-500')).not.toBeNull();
  });

  it('caps the bar width at 100%', () => {
    const { container } = render(<CoverageBar label="X" value={120} administered={12} eligible={10} />);
    const bar = container.querySelector('[role="progressbar"] > div') as HTMLElement;
    expect(bar.style.width).toBe('100%');
  });
});
