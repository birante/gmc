import { fireEvent, screen, waitFor } from '@testing-library/react';
import { Route, Routes } from 'react-router-dom';
import BookFormPage from '../pages/BookFormPage.jsx';
import { mockApi, renderWithProviders } from './helpers.jsx';

function renderForm(route = '/livres/nouveau') {
  return renderWithProviders(
    <Routes>
      <Route path="/livres/nouveau" element={<BookFormPage />} />
      <Route path="/livres/:id/modifier" element={<BookFormPage />} />
      <Route path="/livres/:id" element={<p>Fiche du livre</p>} />
    </Routes>,
    { route }
  );
}

const bodyOf = (fetchMock, key) => {
  const call = fetchMock.mock.calls.find(([u, i = {}]) => `${i.method || 'GET'} ${u}` === key);
  return call ? JSON.parse(call[1].body) : null;
};

describe('BookFormPage (Ajouter un livre)', () => {
  it('crée un livre complet (auteurs en chips, genres, couverture) puis redirige vers la fiche', async () => {
    const fetchMock = mockApi({ 'POST /api/books': { __status: 201, body: { created: true, book: { id: 'new1', title: 'Frère d’âme' } } } });
    renderForm('/livres/nouveau?titre=Fr%C3%A8re%20d%E2%80%99%C3%A2me');
    expect(screen.getByRole('heading', { name: 'Ajouter un livre' })).toBeInTheDocument();
    expect(screen.getByLabelText(/^Titre/)).toHaveValue('Frère d’âme');

    const authors = screen.getByLabelText(/Auteur\(s\)/);
    fireEvent.change(authors, { target: { value: 'David Diop,' } });
    expect(screen.getByRole('button', { name: 'Retirer David Diop' })).toBeInTheDocument();
    fireEvent.change(authors, { target: { value: 'Second Auteur' } });
    fireEvent.keyDown(authors, { key: 'Enter' });
    fireEvent.click(screen.getByRole('button', { name: 'Retirer Second Auteur' }));

    fireEvent.click(screen.getByRole('button', { name: 'Roman' }));
    fireEvent.change(screen.getByLabelText('Ajouter un genre'), { target: { value: 'Guerre' } });
    fireEvent.keyDown(screen.getByLabelText('Ajouter un genre'), { key: 'Enter' });

    // Couverture absente : couverture générée ; URL https : aperçu live
    expect(screen.getByRole('img', { name: 'Couverture de Frère d’âme' }).tagName).toBe('DIV');
    fireEvent.change(screen.getByLabelText(/URL de la couverture/), { target: { value: 'https://example.org/c.jpg' } });
    expect(screen.getByRole('img', { name: 'Couverture de Frère d’âme' })).toHaveAttribute('src', 'https://example.org/c.jpg');

    fireEvent.change(screen.getByLabelText('ISBN'), { target: { value: '978-2-02-139824-3' } });
    fireEvent.change(screen.getByLabelText('Année'), { target: { value: '2018' } });
    fireEvent.change(screen.getByLabelText('Pages'), { target: { value: '176' } });
    fireEvent.click(screen.getByRole('button', { name: 'Ajouter le livre' }));

    expect(await screen.findByText('Fiche du livre')).toBeInTheDocument();
    expect(bodyOf(fetchMock, 'POST /api/books')).toMatchObject({
      title: 'Frère d’âme',
      authors: ['David Diop'],
      genres: ['Roman', 'Guerre'],
      coverUrl: 'https://example.org/c.jpg',
      isbn: '978-2-02-139824-3',
      publishedDate: '2018',
      pageCount: 176,
    });
  });

  it('valide le formulaire côté client (titre, ISBN, URL https) sans appeler l’API', async () => {
    const fetchMock = mockApi({});
    renderForm();
    fireEvent.change(screen.getByLabelText('ISBN'), { target: { value: '9782253109076' } });
    fireEvent.change(screen.getByLabelText(/URL de la couverture/), { target: { value: 'http://exemple.org/c.jpg' } });
    fireEvent.click(screen.getByRole('button', { name: 'Ajouter le livre' }));
    expect(await screen.findByText('Le titre est requis.')).toBeInTheDocument();
    expect(screen.getByText(/ISBN invalide/)).toBeInTheDocument();
    expect(screen.getByText(/doit commencer par https/)).toBeInTheDocument();
    expect(fetchMock.mock.calls.filter(([u]) => u === '/api/books')).toHaveLength(0);
  });

  it('affiche le livre existant en cas de doublon (200)', async () => {
    mockApi({ 'POST /api/books': { created: false, message: 'Ce livre existe déjà', book: { id: 'b9', title: 'Dune' } } });
    renderForm();
    fireEvent.change(screen.getByLabelText(/^Titre/), { target: { value: 'dune' } });
    fireEvent.click(screen.getByRole('button', { name: 'Ajouter le livre' }));
    expect(await screen.findByText(/existe déjà dans le catalogue/)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Voir sa fiche' })).toHaveAttribute('href', '/livres/b9');
  });

  it('modifie un livre existant (PUT) en mode édition', async () => {
    const fetchMock = mockApi({
      'GET /api/books/b1': { book: { id: 'b1', title: 'Ancien titre', authors: ['Moi'], genres: [], canEdit: true }, recommendations: [] },
      'PUT /api/books/b1': { book: { id: 'b1', title: 'Nouveau titre' } },
    });
    renderForm('/livres/b1/modifier');
    const title = await screen.findByDisplayValue('Ancien titre');
    fireEvent.change(title, { target: { value: 'Nouveau titre' } });
    fireEvent.click(screen.getByRole('button', { name: 'Enregistrer les modifications' }));
    expect(await screen.findByText('Fiche du livre')).toBeInTheDocument();
    await waitFor(() => expect(bodyOf(fetchMock, 'PUT /api/books/b1')).toMatchObject({ title: 'Nouveau titre', authors: ['Moi'] }));
  });
});
