import { fireEvent, screen, waitFor } from '@testing-library/react';
import RecommendationCard from '../components/RecommendationCard.jsx';
import { mockApi, renderWithProviders } from './helpers.jsx';

const rec = {
  id: 'r1',
  user: { id: 'u2', username: 'lucas' },
  book: { id: 'b1', title: 'Dune', authors: ['Frank Herbert'], genres: ['Science-fiction'], coverUrl: '', averageRating: 4.5, ratingsCount: 2 },
  review: 'Le meilleur roman de SF.',
  rating: 5,
  likesCount: 2,
  likedByMe: false,
  commentsCount: 1,
  createdAt: new Date().toISOString(),
  reasons: ['following', 'genre'],
};

describe('RecommendationCard', () => {
  beforeEach(() => localStorage.setItem('booknest_token', 'tok'));

  it('affiche le livre, l’avis et les raisons du fil', async () => {
    mockApi({ 'GET /api/auth/me': { user: { id: 'u1', username: 'amina', following: [] } } });
    renderWithProviders(<RecommendationCard rec={rec} />);
    expect(screen.getByRole('link', { name: 'Dune' })).toHaveAttribute('href', '/livres/b1');
    expect(screen.getByText('Le meilleur roman de SF.')).toBeInTheDocument();
    expect(screen.getByText('Lecteur suivi')).toBeInTheDocument();
    expect(screen.getByText('Votre genre favori')).toBeInTheDocument();
    expect(screen.queryByText('Supprimer')).not.toBeInTheDocument();
  });

  it('aime puis n’aime plus une recommandation', async () => {
    const fetchMock = mockApi({
      'GET /api/auth/me': { user: { id: 'u1', username: 'amina', following: [] } },
      'POST /api/recommendations/r1/like': { liked: true, likesCount: 3 },
      'DELETE /api/recommendations/r1/like': { liked: false, likesCount: 2 },
    });
    renderWithProviders(<RecommendationCard rec={rec} />);
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith('/api/auth/me', expect.anything()));
    fireEvent.click(screen.getByRole('button', { name: "J'aime" }));
    await waitFor(() => expect(screen.getByTestId('likes-count')).toHaveTextContent('3'));
    expect(screen.getByRole('button', { name: "Je n'aime plus" })).toHaveAttribute('aria-pressed', 'true');
    fireEvent.click(screen.getByRole('button', { name: "Je n'aime plus" }));
    await waitFor(() => expect(screen.getByTestId('likes-count')).toHaveTextContent('2'));
    const likeCall = fetchMock.mock.calls.find(([u, i]) => u === '/api/recommendations/r1/like' && i.method === 'POST');
    expect(likeCall[1].headers.Authorization).toBe('Bearer tok');
  });

  it('affiche et ajoute des commentaires', async () => {
    mockApi({
      'GET /api/auth/me': { user: { id: 'u1', username: 'amina', following: [] } },
      'GET /api/recommendations/r1/comments': { comments: [{ id: 'c1', user: { id: 'u3', username: 'sofia' }, text: 'Bien vu !', createdAt: new Date().toISOString() }] },
      'POST /api/recommendations/r1/comments': (_u, init) => ({ comment: { id: 'c2', user: { id: 'u1', username: 'amina' }, text: JSON.parse(init.body).text, createdAt: new Date().toISOString() } }),
    });
    renderWithProviders(<RecommendationCard rec={rec} />);
    fireEvent.click(screen.getByRole('button', { name: /1 commentaire/ }));
    expect(await screen.findByText('Bien vu !')).toBeInTheDocument();
    await screen.findByLabelText('Votre commentaire');
    fireEvent.change(screen.getByLabelText('Votre commentaire'), { target: { value: 'Je confirme' } });
    fireEvent.click(screen.getByRole('button', { name: 'Publier' }));
    expect(await screen.findByText('Je confirme')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /2 commentaires/ })).toBeInTheDocument();
  });
});
