import { fireEvent, render, screen } from '@testing-library/react';
import StarRating from '../components/StarRating.jsx';

describe('StarRating', () => {
  it('affiche la note en lecture seule', () => {
    render(<StarRating value={3.5} label="Note moyenne" />);
    expect(screen.getByRole('img', { name: 'Note moyenne : 3.5 sur 5' })).toBeInTheDocument();
  });

  it('permet de voter quand onRate est fourni', () => {
    const onRate = vi.fn();
    render(<StarRating value={2} onRate={onRate} label="Noter" />);
    const stars = screen.getAllByRole('radio');
    expect(stars).toHaveLength(5);
    expect(stars[1]).toHaveAttribute('aria-checked', 'true');
    fireEvent.click(screen.getByRole('radio', { name: '4 étoiles' }));
    expect(onRate).toHaveBeenCalledWith(4);
  });
});
