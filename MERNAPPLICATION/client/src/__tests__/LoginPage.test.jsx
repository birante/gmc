import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { vi } from 'vitest';
import LoginPage from '../pages/LoginPage.jsx';
import { AuthContext } from '../context/AuthContext.jsx';
import { ToastProvider } from '../context/ToastContext.jsx';

const renderLogin = (login) =>
  render(
    <ToastProvider>
      <AuthContext.Provider value={{ user: null, login }}>
        <MemoryRouter initialEntries={['/login']} future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/dashboard" element={<p>Page tableau de bord</p>} />
          </Routes>
        </MemoryRouter>
      </AuthContext.Provider>
    </ToastProvider>
  );

describe('LoginPage', () => {
  it('connecte puis redirige vers le tableau de bord', async () => {
    const login = vi.fn().mockResolvedValue({ name: 'Aminata' });
    renderLogin(login);
    await userEvent.type(screen.getByLabelText('E-mail'), 'aminata@eventhub.dev');
    await userEvent.type(screen.getByLabelText('Mot de passe'), 'password123');
    await userEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(login).toHaveBeenCalledWith('aminata@eventhub.dev', 'password123');
    expect(await screen.findByText('Page tableau de bord')).toBeInTheDocument();
  });

  it("affiche l'erreur renvoyée par l'API", async () => {
    const login = vi.fn().mockRejectedValue(new Error('E-mail ou mot de passe incorrect'));
    renderLogin(login);
    await userEvent.type(screen.getByLabelText('E-mail'), 'x@y.dev');
    await userEvent.type(screen.getByLabelText('Mot de passe'), 'mauvais');
    await userEvent.click(screen.getByRole('button', { name: 'Se connecter' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('E-mail ou mot de passe incorrect');
  });
});
