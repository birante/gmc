import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../utils/api.js';
import { formatDate } from '../utils/format.js';
import Price from '../components/Price.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import Spinner from '../components/Spinner.jsx';

export default function Orders() {
  const [orders, setOrders] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api('/orders/mine').then(setOrders).catch((e) => setError(e.message));
  }, []);

  if (error) return <div className="container page"><p className="alert alert-error">{error}</p></div>;
  if (!orders) return <Spinner />;

  return (
    <div className="container page">
      <h1>Mes commandes</h1>
      {orders.length === 0 ? (
        <div className="empty">
          <h2>Aucune commande pour l'instant</h2>
          <Link to="/produits" className="btn btn-primary">Commencer mes achats</Link>
        </div>
      ) : (
        <ul className="order-list">
          {orders.map((o) => (
            <li key={o.id} className="card order-row">
              <div>
                <strong>Commande #{o.id.slice(-6).toUpperCase()}</strong>
                <div className="muted small">{formatDate(o.createdAt)} · {o.items.reduce((s, i) => s + i.quantity, 0)} article(s)</div>
              </div>
              <StatusBadge status={o.status} />
              <Price value={o.total} />
              <Link to={`/mes-commandes/${o.id}`} className="btn btn-ghost btn-sm">Détails</Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
