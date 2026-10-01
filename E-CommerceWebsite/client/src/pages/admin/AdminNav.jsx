import { NavLink } from 'react-router-dom';

export default function AdminNav() {
  return (
    <nav className="tabs" aria-label="Administration">
      <NavLink to="/admin" end>Produits</NavLink>
      <NavLink to="/admin/commandes">Commandes</NavLink>
    </nav>
  );
}
