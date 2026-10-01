import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { vi } from 'vitest';
import Navbar from '../components/Navbar.jsx';
import { AuthContext } from '../context/AuthContext.jsx';

const renderWith = (value) =>
  render(
    <AuthContext.Provider value={value}>
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <Navbar />
      </MemoryRouter>
    </AuthContext.Provider>
  );

describe('Navbar', () => {
  it('propose connexion et inscription aux visiteurs', () => {
    renderWith({ user: null });
    expect(screen.getByRole('link', { name: 'Connexion' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: "S'inscrire" })).toBeInTheDocument();
    expect(screen.queryByText('Tableau de bord')).not.toBeInTheDocument();
  });

  it("affiche le tableau de bord et permet la déconnexion d'un utilisateur connecté", async () => {
    const logout = vi.fn();
    renderWith({ user: { name: 'Aminata Diop' }, logout });
    expect(screen.getByText('Tableau de bord')).toBeInTheDocument();
    expect(screen.getByText('AD')).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Déconnexion' }));
    expect(logout).toHaveBeenCalledOnce();
  });
});
