import { useEffect, useState } from 'react';
import { api } from '../../utils/api.js';
import { formatDate, STATUS_LABELS } from '../../utils/format.js';
import Price from '../../components/Price.jsx';
import StatusBadge from '../../components/StatusBadge.jsx';
import Spinner from '../../components/Spinner.jsx';
import AdminNav from './AdminNav.jsx';

export default function AdminOrders() {
  const [orders, setOrders] = useState(null);
  const [filter, setFilter] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    setOrders(null);
    api('/orders', { query: { status: filter } }).then(setOrders).catch((e) => setError(e.message));
  }, [filter]);

  const changeStatus = async (order, status) => {
    if (status === 'cancelled' && !window.confirm('Annuler cette commande ? Le stock sera restitué.')) return;
    setError('');
    try {
      const updated = await api(`/orders/${order.id}/status`, { method: 'PATCH', body: { status } });
      setOrders((list) => list.map((o) => (o.id === updated.id ? updated : o)));
    } catch (e) {
      setError(e.message);
    }
  };

  const revenue = (orders || []).filter((o) => o.status !== 'pending' && o.status !== 'cancelled').reduce((s, o) => s + o.total, 0);

  return (
    <div className="container page">
      <div className="page-head"><h1>Administration</h1></div>
      <AdminNav />
      <div className="toolbar">
        <label className="sort">
          Statut
          <select value={filter} onChange={(e) => setFilter(e.target.value)}>
            <option value="">Tous</option>
            {Object.entries(STATUS_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select>
        </label>
        {orders && <span className="muted">{orders.length} commande(s) · CA encaissé : <Price value={revenue} /></span>}
      </div>
      {error && <p className="alert alert-error">{error}</p>}
      {!orders ? <Spinner /> : (
        <div className="card table-wrap">
          <table className="table">
            <thead><tr><th>Commande</th><th>Client</th><th>Date</th><th>Total</th><th>Statut</th><th>Changer</th></tr></thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.id}>
                  <td>
                    <strong>#{o.id.slice(-6).toUpperCase()}</strong>
                    <div className="muted small">{o.items.map((i) => `${i.quantity}× ${i.name}`).join(', ')}</div>
                  </td>
                  <td>{o.user?.name || '—'}<div className="muted small">{o.user?.email}</div></td>
                  <td className="small">{formatDate(o.createdAt)}</td>
                  <td><Price value={o.total} /></td>
                  <td><StatusBadge status={o.status} /></td>
                  <td>
                    <select value={o.status} onChange={(e) => changeStatus(o, e.target.value)} disabled={o.status === 'cancelled'} aria-label={`Statut de la commande ${o.id.slice(-6)}`}>
                      {Object.entries(STATUS_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                    </select>
                  </td>
                </tr>
              ))}
              {orders.length === 0 && <tr><td colSpan="6" className="muted">Aucune commande.</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
