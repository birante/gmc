import { useEffect, useState } from 'react';
import { Link, useLocation, useParams } from 'react-router-dom';
import { api } from '../utils/api.js';
import { formatDate, STATUS_FLOW, STATUS_LABELS } from '../utils/format.js';
import Price from '../components/Price.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import Spinner from '../components/Spinner.jsx';

export default function OrderDetail() {
  const { id } = useParams();
  const location = useLocation();
  const [order, setOrder] = useState(null);
  const [error, setError] = useState('');
  const [paying, setPaying] = useState(false);
  const [payError, setPayError] = useState('');

  useEffect(() => {
    api(`/orders/${id}`).then(setOrder).catch((e) => setError(e.status === 404 ? 'Commande introuvable.' : e.message));
  }, [id]);

  const pay = async () => {
    setPaying(true);
    setPayError('');
    try {
      // Simulation d'un délai de passerelle de paiement
      await new Promise((r) => setTimeout(r, 600));
      setOrder(await api(`/orders/${id}/pay`, { method: 'POST' }));
    } catch (e) {
      setPayError(e.message);
    } finally {
      setPaying(false);
    }
  };

  if (error) return <div className="container page"><div className="empty"><h2>{error}</h2><Link to="/mes-commandes" className="btn btn-primary">Mes commandes</Link></div></div>;
  if (!order) return <Spinner />;

  const step = STATUS_FLOW.indexOf(order.status);

  return (
    <div className="container page">
      <Link to="/mes-commandes" className="link">← Mes commandes</Link>
      <div className="page-head">
        <h1>Commande #{order.id.slice(-6).toUpperCase()}</h1>
        <StatusBadge status={order.status} />
      </div>
      {location.state?.justCreated && order.status === 'pending' && (
        <p className="alert alert-success">Merci ! Votre commande a bien été enregistrée. Il ne reste plus qu'à la payer.</p>
      )}

      {order.status !== 'cancelled' ? (
        <ol className="timeline" aria-label="Suivi de la commande">
          {STATUS_FLOW.map((s, i) => (
            <li key={s} className={i <= step ? 'done' : ''}><span className="dot" />{STATUS_LABELS[s]}</li>
          ))}
        </ol>
      ) : (
        <p className="alert alert-error">Cette commande a été annulée.</p>
      )}

      <div className="cart-layout">
        <div className="card">
          <h2>Articles</h2>
          <table className="table">
            <thead><tr><th>Produit</th><th>Prix</th><th>Qté</th><th>Sous-total</th></tr></thead>
            <tbody>
              {order.items.map((i) => (
                <tr key={i.product}>
                  <td>{i.name}</td><td><Price value={i.price} /></td><td>{i.quantity}</td><td><Price value={i.price * i.quantity} /></td>
                </tr>
              ))}
            </tbody>
            <tfoot><tr><td colSpan="3"><strong>Total</strong></td><td><Price value={order.total} className="price-strong" /></td></tr></tfoot>
          </table>
        </div>
        <aside className="summary card">
          <h2>Livraison</h2>
          <address>
            <strong>{order.shippingAddress.fullName}</strong><br />
            {order.shippingAddress.address}<br />
            {order.shippingAddress.city}<br />
            {order.shippingAddress.phone}
          </address>
          <p className="muted small">Passée le {formatDate(order.createdAt)}</p>
          {order.paymentRef && <p className="small">Référence de paiement : <code>{order.paymentRef}</code></p>}
          {order.status === 'pending' && (
            <>
              <button type="button" className="btn btn-primary btn-block btn-lg" onClick={pay} disabled={paying}>
                {paying ? 'Paiement en cours…' : 'Payer maintenant'}
              </button>
              <p className="muted small">Paiement simulé : aucune carte n'est débitée.</p>
            </>
          )}
          {payError && <p className="alert alert-error">{payError}</p>}
        </aside>
      </div>
    </div>
  );
}
