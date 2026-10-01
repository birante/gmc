import { useState } from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { useCart } from '../context/CartContext.jsx';

export default function Header() {
  const { user, isAdmin, logout } = useAuth();
  const { count } = useCart();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const navigate = useNavigate();
  const close = () => setOpen(false);

  const onSearch = (e) => {
    e.preventDefault();
    navigate(q.trim() ? `/produits?search=${encodeURIComponent(q.trim())}` : '/produits');
    close();
  };

  return (
    <header className="header">
      <div className="topbar">Livraison partout au Sénégal · Paiement à la commande sécurisé</div>
      <div className="container header-inner">
        <Link to="/" className="logo" onClick={close}>
          <span className="logo-mark" aria-hidden="true">B</span>
          Boutik
        </Link>

        <form className="header-search" onSubmit={onSearch} role="search">
          <input type="search" placeholder="Rechercher un produit…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Rechercher" />
          <button type="submit" aria-label="Lancer la recherche">🔍</button>
        </form>

        <button type="button" className="burger" aria-label="Menu" aria-expanded={open} onClick={() => setOpen((o) => !o)}>
          <span /><span /><span />
        </button>

        <nav className={`nav ${open ? 'nav-open' : ''}`} aria-label="Navigation principale">
          <NavLink to="/" end onClick={close}>Accueil</NavLink>
          <NavLink to="/produits" onClick={close}>Catalogue</NavLink>
          {user && <NavLink to="/mes-commandes" onClick={close}>Mes commandes</NavLink>}
          {isAdmin && <NavLink to="/admin" onClick={close}>Admin</NavLink>}
          {user ? (
            <button type="button" className="link-btn" onClick={() => { logout(); close(); navigate('/'); }}>
              Déconnexion <small>({user.name.split(' ')[0]})</small>
            </button>
          ) : (
            <NavLink to="/connexion" onClick={close}>Connexion</NavLink>
          )}
        </nav>

        <Link to="/panier" className="cart-link" onClick={close} aria-label={`Panier : ${count} article(s)`}>
          <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
            <path fill="currentColor" d="M7 18a2 2 0 1 0 0 4 2 2 0 0 0 0-4Zm10 0a2 2 0 1 0 0 4 2 2 0 0 0 0-4ZM5.2 4H2V2h4.8l.9 2H22l-3.6 8.4a2 2 0 0 1-1.8 1.2H8.1l-1 1.8V16H19v2H6a2 2 0 0 1-1.7-3l1.4-2.5L5.2 4Z" />
          </svg>
          <span className="cart-count" data-testid="cart-count">{count}</span>
        </Link>
      </div>
    </header>
  );
}
