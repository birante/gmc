import { useEffect, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function Layout() {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => setOpen(false), [location.pathname]);

  return (
    <div className="app">
      <header className="topbar">
        <div className="container topbar__inner">
          <Link to="/" className="brand" aria-label="BookNest, accueil">
            <span className="brand__mark" aria-hidden="true">
              <svg viewBox="0 0 64 64" width="30" height="30"><path d="M10 16c8-3 15-2 22 3v31c-7-5-14-6-22-3z" fill="currentColor" opacity=".9"/><path d="M54 16c-8-3-15-2-22 3v31c7-5 14-6 22-3z" fill="currentColor" opacity=".6"/></svg>
            </span>
            <span className="brand__name">BookNest</span>
          </Link>
          <button className="burger" aria-label="Menu" aria-expanded={open} onClick={() => setOpen((o) => !o)}>
            <span /><span /><span />
          </button>
          <nav className={`nav ${open ? 'nav--open' : ''}`}>
            <NavLink to="/" end>{user ? 'Mon fil' : 'Accueil'}</NavLink>
            <NavLink to="/recherche">Rechercher</NavLink>
            <NavLink to="/bibliotheque" end>Bibliothèque</NavLink>
            <NavLink to="/livres/nouveau">Ajouter un livre</NavLink>
            <NavLink to="/lecteurs" end>Lecteurs</NavLink>
            {user ? (
              <>
                <NavLink to="/recommander" className="nav__cta">+ Recommander</NavLink>
                <NavLink to={`/lecteurs/${user.username}`} className="nav__user">
                  <span className="avatar avatar--sm" aria-hidden="true">{user.username[0].toUpperCase()}</span>
                  {user.username}
                </NavLink>
                <button
                  className="linklike"
                  onClick={() => {
                    logout();
                    navigate('/');
                  }}
                >
                  Déconnexion
                </button>
              </>
            ) : (
              <>
                <NavLink to="/connexion">Connexion</NavLink>
                <NavLink to="/inscription" className="nav__cta">Rejoindre</NavLink>
              </>
            )}
          </nav>
        </div>
      </header>
      <main className="container main">
        <Outlet />
      </main>
      <footer className="footer">
        <div className="container">
          <p>BookNest · des livres recommandés par de vrais lecteurs</p>
          <p className="muted small">Catalogue BookNest enrichi par ses lecteurs · recherche complémentaire via Open Library</p>
        </div>
      </footer>
    </div>
  );
}
