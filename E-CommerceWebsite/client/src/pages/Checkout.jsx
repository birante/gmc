import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext.jsx';
import { useAuth } from '../context/AuthContext.jsx';
import { api } from '../utils/api.js';
import Price from '../components/Price.jsx';
import Spinner from '../components/Spinner.jsx';

export default function Checkout() {
  const { items, total, syncWith, clear } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [syncing, setSyncing] = useState(true);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState({ fullName: user?.name || '', address: '', city: 'Dakar', phone: '' });
  const synced = useRef(false);

  // Synchronise le panier local avec les prix et stocks réels du serveur
  useEffect(() => {
    if (synced.current) return;
    synced.current = true;
    if (items.length === 0) { setSyncing(false); return; }
    Promise.all(items.map((i) => api(`/products/${i.id}`).catch(() => null)))
      .then((fresh) => {
        const changed = items.some((i, idx) => {
          const p = fresh[idx];
          return !p || p.price !== i.price || p.stock < i.quantity;
        });
        syncWith(fresh);
        if (changed) setNotice('Votre panier a été mis à jour selon les prix et stocks actuels.');
      })
      .finally(() => setSyncing(false));
  }, [items, syncWith]);

  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const order = await api('/orders', {
        method: 'POST',
        body: { items: items.map((i) => ({ product: i.id, quantity: i.quantity })), shippingAddress: form }
      });
      clear();
      navigate(`/mes-commandes/${order.id}`, { state: { justCreated: true } });
    } catch (err) {
      setError(err.message);
      setSubmitting(false);
    }
  };

  if (syncing) return <Spinner label="Vérification du panier…" />;

  if (items.length === 0) {
    return (
      <div className="container page">
        <div className="empty">
          <h2>Votre panier est vide</h2>
          {notice && <p>{notice}</p>}
          <Link to="/produits" className="btn btn-primary">Retour au catalogue</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container page">
      <h1>Finaliser la commande</h1>
      {notice && <p className="alert alert-info">{notice}</p>}
      <div className="cart-layout">
        <form className="card form" onSubmit={onSubmit}>
          <h2>Adresse de livraison</h2>
          <label className="field"><span>Nom complet</span><input name="fullName" value={form.fullName} onChange={onChange} required minLength={2} /></label>
          <label className="field"><span>Adresse</span><input name="address" value={form.address} onChange={onChange} required minLength={3} placeholder="Rue, quartier…" /></label>
          <div className="row-2">
            <label className="field"><span>Ville</span><input name="city" value={form.city} onChange={onChange} required minLength={2} /></label>
            <label className="field"><span>Téléphone</span><input name="phone" type="tel" value={form.phone} onChange={onChange} required minLength={6} placeholder="77 123 45 67" /></label>
          </div>
          {error && <p className="alert alert-error" role="alert">{error}</p>}
          <button type="submit" className="btn btn-primary btn-lg btn-block" disabled={submitting}>
            {submitting ? 'Validation…' : `Valider la commande (${new Intl.NumberFormat('fr-FR').format(total).replace(/ | /g, ' ')} FCFA)`}
          </button>
        </form>
        <aside className="summary card">
          <h2>Votre commande</h2>
          <ul className="summary-items">
            {items.map((i) => (
              <li key={i.id}><span>{i.quantity} × {i.name}</span><Price value={i.price * i.quantity} /></li>
            ))}
          </ul>
          <div className="summary-row summary-total"><span>Total</span><Price value={total} /></div>
          <p className="muted small">Le paiement (simulé) se fait à l'étape suivante.</p>
        </aside>
      </div>
    </div>
  );
}
