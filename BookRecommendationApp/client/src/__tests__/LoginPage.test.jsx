import { fireEvent, screen } from '@testing-library/react';
import { Route, Routes } from 'react-router-dom';
import LoginPage from '../pages/LoginPage.jsx';
import { mockApi, renderWithProviders } from './helpers.jsx';

function renderLogin() {
  return renderWithProviders(
    <Routes>
      <Route path="/connexion" element={<LoginPage />} />
      <Route path="/" element={<p>Accueil connecté</p>} />
    </Routes>,
    { route: '/connexion' }
  );
}

describe('LoginPage', () => {
  it("affiche l'erreur renvoyée par l'API", async () => {
    mockApi({ 'POST /api/auth/login': { __status: 401, body: { error: 'Email ou mot de passe incorrect' } } });
    renderLogin();
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'a@b.fr' } });
    fireEvent.change(screen.getByLabelText('Mot de passe'), { target: { value: 'mauvais' } });
    fireEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Email ou mot de passe incorrect');
  });

  it('stocke le jeton et redirige après connexion', async () => {
    mockApi({ 'POST /api/auth/login': { token: 'jwt-123', user: { id: 'u1', username: 'amina' } } });
    renderLogin();
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'amina@booknest.app' } });
    fireEvent.change(screen.getByLabelText('Mot de passe'), { target: { value: 'password123' } });
    fireEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(await screen.findByText('Accueil connecté')).toBeInTheDocument();
    expect(localStorage.getItem('booknest_token')).toBe('jwt-123');
  });
});
