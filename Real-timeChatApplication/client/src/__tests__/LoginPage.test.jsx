import { afterEach, describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext.jsx';
import LoginPage from '../pages/LoginPage.jsx';

function setup() {
  return render(
    <MemoryRouter initialEntries={['/connexion']}>
      <AuthProvider>
        <Routes>
          <Route path="/connexion" element={<LoginPage />} />
          <Route path="/" element={<p>Accueil chat</p>} />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

const jsonResponse = (status, body) => ({ ok: status < 400, status, json: async () => body });

afterEach(() => vi.unstubAllGlobals());

describe('LoginPage', () => {
  it('connecte et stocke le jeton', async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse(200, { token: 'jwt-123', user: { id: 'u1', username: 'awa', email: 'awa@waxtaan.sn' } }),
    );
    vi.stubGlobal('fetch', fetchMock);
    setup();
    await userEvent.type(screen.getByLabelText('Email'), 'awa@waxtaan.sn');
    await userEvent.type(screen.getByLabelText('Mot de passe'), 'password123');
    await userEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(await screen.findByText('Accueil chat')).toBeInTheDocument();
    expect(fetchMock).toHaveBeenCalledWith('/api/auth/login', expect.objectContaining({ method: 'POST' }));
    expect(JSON.parse(fetchMock.mock.calls[0][1].body)).toEqual({ email: 'awa@waxtaan.sn', password: 'password123' });
    expect(localStorage.getItem('waxtaan_token')).toBe('jwt-123');
  });

  it("affiche l'erreur du serveur", async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(401, { error: 'Email ou mot de passe incorrect' })));
    setup();
    await userEvent.type(screen.getByLabelText('Email'), 'awa@waxtaan.sn');
    await userEvent.type(screen.getByLabelText('Mot de passe'), 'faux');
    await userEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Email ou mot de passe incorrect');
  });

  it('valide les champs vides', async () => {
    vi.stubGlobal('fetch', vi.fn());
    setup();
    await userEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(screen.getByRole('alert')).toHaveTextContent('Renseignez votre email');
  });
});
