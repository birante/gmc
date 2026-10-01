import { fireEvent, render, screen } from '@testing-library/react';
import BookCover from '../components/BookCover.jsx';

describe('BookCover', () => {
  it("affiche l'image de couverture", () => {
    render(<BookCover book={{ title: 'Dune', coverUrl: 'https://img.test/dune.jpg' }} />);
    expect(screen.getByAltText('Couverture de Dune')).toHaveAttribute('src', 'https://img.test/dune.jpg');
  });

  it("génère une couverture si l'image manque ou échoue", () => {
    const { rerender } = render(<BookCover book={{ title: 'Sans image', authors: ['Anonyme'] }} />);
    expect(screen.getByRole('img', { name: 'Couverture de Sans image' })).toHaveTextContent('Sans image');
    rerender(<BookCover book={{ title: 'Cassée', coverUrl: 'https://img.test/x.jpg' }} />);
    fireEvent.error(screen.getByAltText('Couverture de Cassée'));
    expect(screen.getByRole('img', { name: 'Couverture de Cassée' })).toHaveTextContent('Cassée');
  });
});
