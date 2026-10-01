import { fireEvent, screen } from '@testing-library/react';
import { Route, Routes } from 'react-router-dom';
import SearchPage from '../pages/SearchPage.jsx';
import { mockApi, renderWithProviders } from './helpers.jsx';

function renderSearch(route = '/recherche') {
  return renderWithProviders(
    <Routes>
      <Route path="/recherche" element={<SearchPage />} />
      <Route path="/livres/nouveau" element={<p>Formulaire nouveau livre</p>} />
    </Routes>,
    { route }
  );
}

const local = { id: 'b1', source: 'booknest', externalId: null, title: 'Une si longue lettre', authors: ['Mariama Bâ'], genres: ['Roman'], coverUrl: '', averageRating: 4.5, ratingsCount: 2 };
const external = { id: null, source: 'openlibrary', externalId: 'ol:/works/OL1W', title: 'So Long a Letter', authors: ['Mariama Bâ'], genres: ['Fiction'], coverUrl: '', averageRating: 0, ratingsCount: 0 };

describe('SearchPage', () => {
  it('recherche par auteur : catalogue BookNest en tête puis résultats Open Library', async () => {
    const fetchMock = mockApi({
      'GET /api/books/search': { results: [local, external], localCount: 1, externalCount: 1, externalEnabled: true, externalAvailable: true },
    });
    renderSearch();
    fireEvent.click(screen.getByRole('radio', { name: 'Auteur' }));
    fireEvent.change(screen.getByLabelText('Recherche'), { target: { value: 'Mariama Bâ' } });
    fireEvent.click(screen.getByRole('button', { name: 'Rechercher' }));
    expect(await screen.findByRole('link', { name: 'Une si longue lettre' })).toHaveAttribute('href', '/livres/b1');
    // Le résultat externe n'a pas de fiche locale : pas de lien, badge + bouton d'import
    expect(screen.queryByRole('link', { name: 'So Long a Letter' })).toBeNull();
    expect(screen.getByRole('heading', { name: 'So Long a Letter' })).toBeInTheDocument();
    expect(screen.getByText('Open Library')).toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: 'Ajouter au catalogue' })).toHaveLength(1);
    expect(screen.getByText(/1 résultat dans le catalogue BookNest · 1 résultat via Open Library/)).toBeInTheDocument();
    const url = fetchMock.mock.calls.map(([u]) => u).find((u) => u.startsWith('/api/books/search'));
    expect(url).toContain('type=author');
    expect(url).toContain('q=Mariama');
  });

  it('signale Open Library injoignable et propose « Ajouter ce livre » sans résultat', async () => {
    mockApi({ 'GET /api/books/search': { results: [], localCount: 0, externalCount: 0, externalEnabled: true, externalAvailable: false } });
    renderSearch('/recherche?q=Livre%20introuvable&type=title');
    expect(await screen.findByText(/Open Library est momentanément injoignable/)).toBeInTheDocument();
    expect(screen.getByText('Aucun résultat pour « Livre introuvable ».')).toBeInTheDocument();
    const add = screen.getByRole('link', { name: 'Ajouter ce livre' });
    expect(add).toHaveAttribute('href', '/livres/nouveau?titre=Livre+introuvable');
    fireEvent.click(add);
    expect(await screen.findByText('Formulaire nouveau livre')).toBeInTheDocument();
  });

  it("n'affiche pas d'avertissement quand la recherche externe est désactivée", async () => {
    mockApi({ 'GET /api/books/search': { results: [local], localCount: 1, externalCount: 0, externalEnabled: false, externalAvailable: false } });
    renderSearch('/recherche?q=lettre');
    expect(await screen.findByRole('link', { name: 'Une si longue lettre' })).toBeInTheDocument();
    expect(screen.queryByText(/injoignable/)).toBeNull();
  });
});
