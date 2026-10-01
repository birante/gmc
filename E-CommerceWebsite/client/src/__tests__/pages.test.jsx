import { screen, fireEvent, waitFor } from '@testing-library/react';
import { Routes, Route } from 'react-router-dom';
import Catalog from '../pages/Catalog.jsx';
import Login from '../pages/Login.jsx';
import ProtectedRoute from '../components/ProtectedRoute.jsx';
import { renderWithProviders, sampleProduct, mockFetch } from './helpers.jsx';

describe('Catalogue', () => {
  it('affiche les produits et transmet les filtres à l\'API', async () => {
    const fetchMock = mockFetch((url) => {
      if (url.startsWith('/api/categories')) return { body: [{ name: 'Mode', count: 1 }] };
      return { body: { items: [sampleProduct], total: 1, page: 1, limit: 12, pages: 1 } };
    });
    renderWithProviders(<Catalog />, { route: '/produits?category=Mode' });
    expect(await screen.findByText('Robe wax')).toBeInTheDocument();
    expect(screen.getByText('18 500 FCFA')).toBeInTheDocument();
    expect(fetchMock.mock.calls.some(([u]) => String(u).includes('category=Mode'))).toBe(true);

    fireEvent.change(screen.getByLabelText(/trier par/i), { target: { value: 'price_asc' } });
    await waitFor(() => expect(fetchMock.mock.calls.some(([u]) => String(u).includes('sort=price_asc'))).toBe(true));
  });

  it('affiche un message si aucun produit', async () => {
    mockFetch((url) => (url.startsWith('/api/categories') ? { body: [] } : { body: { items: [], total: 0, page: 1, pages: 1 } }));
    renderWithProviders(<Catalog />, { route: '/produits' });
    expect(await screen.findByText(/aucun produit trouvé/i)).toBeInTheDocument();
  });
});

describe('Authentification', () => {
  it('affiche l\'erreur renvoyée par le serveur', async () => {
    mockFetch(() => ({ status: 401, body: { error: 'Email ou mot de passe incorrect' } }));
    renderWithProviders(<Login />, { route: '/connexion' });
    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'a@b.sn' } });
    fireEvent.change(screen.getByLabelText(/mot de passe/i), { target: { value: 'x' } });
    fireEvent.click(screen.getByRole('button', { name: /se connecter/i }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Email ou mot de passe incorrect');
  });

  it('connecte et stocke le jeton', async () => {
    mockFetch(() => ({ body: { token: 'tok', user: { id: 'u1', name: 'Awa', email: 'a@b.sn', role: 'client' } } }));
    renderWithProviders(
      <Routes>
        <Route path="/connexion" element={<Login />} />
        <Route path="/" element={<p>Accueil OK</p>} />
      </Routes>,
      { route: '/connexion' }
    );
    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'a@b.sn' } });
    fireEvent.change(screen.getByLabelText(/mot de passe/i), { target: { value: 'secret123' } });
    fireEvent.click(screen.getByRole('button', { name: /se connecter/i }));
    expect(await screen.findByText('Accueil OK')).toBeInTheDocument();
    expect(localStorage.getItem('boutik_token')).toBe('tok');
  });

  it('redirige vers la connexion pour une page protégée', () => {
    renderWithProviders(
      <Routes>
        <Route path="/connexion" element={<p>Page connexion</p>} />
        <Route path="/mes-commandes" element={<ProtectedRoute><p>Secret</p></ProtectedRoute>} />
      </Routes>,
      { route: '/mes-commandes' }
    );
    expect(screen.getByText('Page connexion')).toBeInTheDocument();
  });

  it('refuse l\'espace admin à un client', async () => {
    localStorage.setItem('boutik_token', 'tok');
    mockFetch(() => ({ body: { user: { id: 'u1', name: 'Awa', email: 'a@b.sn', role: 'client' } } }));
    renderWithProviders(
      <Routes><Route path="/admin" element={<ProtectedRoute admin><p>Admin</p></ProtectedRoute>} /></Routes>,
      { route: '/admin' }
    );
    expect(await screen.findByText(/accès refusé/i)).toBeInTheDocument();
    expect(screen.queryByText('Admin')).not.toBeInTheDocument();
  });
});
