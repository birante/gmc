import { useState } from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { initials } from '../utils/format.js';

export default function Navbar() {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const navigate = useNavigate();
  const close = () => setOpen(false);

  const handleLogout = () => {
    logout();
    close();
    navigate('/');
  };

  return (
    <header className="navbar">
      <div className="container navbar-inner">
        <Link to="/" className="brand" onClick={close}>
          <span className="brand-logo" aria-hidden="true">🎟️</span>
          <span>Event<strong>Hub</strong></span>
        </Link>

        <button
          type="button"
          className="nav-toggle"
          aria-label="Ouvrir le menu"
          aria-expanded={open}
          onClick={() => setOpen((o) => !o)}
        >
          <span />
          <span />
          <span />
        </button>

        <nav className={`nav-links ${open ? 'open' : ''}`} aria-label="Navigation principale">
          <NavLink to="/" end onClick={close}>Événements</NavLink>
          {user ? (
            <>
              <NavLink to="/dashboard" onClick={close}>Tableau de bord</NavLink>
              <NavLink to="/events/new" className="btn btn-primary btn-sm" onClick={close}>
                + Créer
              </NavLink>
              <NavLink to="/profile" className="nav-user" onClick={close} title="Mon profil">
                <span className="avatar avatar-sm">{initials(user.name)}</span>
                <span className="nav-user-name">{user.name}</span>
              </NavLink>
              <button type="button" className="btn btn-ghost btn-sm" onClick={handleLogout}>
                Déconnexion
              </button>
            </>
          ) : (
            <>
              <NavLink to="/login" onClick={close}>Connexion</NavLink>
              <NavLink to="/register" className="btn btn-primary btn-sm" onClick={close}>
                S'inscrire
              </NavLink>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
