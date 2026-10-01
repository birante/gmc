import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function Header() {
  const { user, logout } = useAuth();
  return (
    <header className="topbar">
      <div className="container topbar-inner">
        <Link to="/" className="brand" aria-label="TaskFlow, accueil">
          <span className="brand-logo" aria-hidden="true">✓</span>
          TaskFlow
        </Link>
        {user && (
          <div className="topbar-user">
            <span className="avatar" aria-hidden="true">{user.name.charAt(0).toUpperCase()}</span>
            <span className="user-name">{user.name}</span>
            <button type="button" className="btn btn-ghost btn-sm" onClick={logout}>Déconnexion</button>
          </div>
        )}
      </div>
    </header>
  );
}
