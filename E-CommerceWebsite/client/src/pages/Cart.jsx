import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext.jsx';
import Price from '../components/Price.jsx';

export default function Cart() {
  const { items, total, count, updateQuantity, removeItem, clear } = useCart();
  const navigate = useNavigate();

  if (items.length === 0) {
    return (
      <div className="container page">
        <div className="empty">
          <h2>Votre panier est vide</h2>
          <p>Parcourez notre catalogue et ajoutez vos coups de cœur.</p>
          <Link to="/produits" className="btn btn-primary">Découvrir les produits</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container page">
      <h1>Mon panier</h1>
      <div className="cart-layout">
        <ul className="cart-list card">
          {items.map((i) => (
            <li key={i.id} className="cart-item">
              <img src={i.imageUrl} alt="" width="80" height="80" />
              <div className="cart-item-info">
                <Link to={`/produits/${i.slug}`} className="cart-item-name">{i.name}</Link>
                <Price value={i.price} className="muted" />
              </div>
              <div className="qty">
                <button type="button" onClick={() => updateQuantity(i.id, i.quantity - 1)} aria-label={`Diminuer ${i.name}`}>−</button>
                <span>{i.quantity}</span>
                <button type="button" onClick={() => updateQuantity(i.id, i.quantity + 1)} disabled={i.stock != null && i.quantity >= i.stock} aria-label={`Augmenter ${i.name}`}>+</button>
              </div>
              <Price value={i.price * i.quantity} className="cart-line-total" />
              <button type="button" className="icon-btn" onClick={() => removeItem(i.id)} aria-label={`Retirer ${i.name}`}>✕</button>
            </li>
          ))}
        </ul>
        <aside className="summary card">
          <h2>Récapitulatif</h2>
          <div className="summary-row"><span>Articles ({count})</span><Price value={total} /></div>
          <div className="summary-row"><span>Livraison</span><span>Offerte</span></div>
          <div className="summary-row summary-total"><span>Total</span><Price value={total} /></div>
          <button type="button" className="btn btn-primary btn-block btn-lg" onClick={() => navigate('/commande')}>Passer la commande</button>
          <button type="button" className="btn btn-ghost btn-block" onClick={clear}>Vider le panier</button>
        </aside>
      </div>
    </div>
  );
}
