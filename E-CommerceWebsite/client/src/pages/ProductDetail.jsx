import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../utils/api.js';
import { useCart } from '../context/CartContext.jsx';
import Price from '../components/Price.jsx';
import Rating from '../components/Rating.jsx';
import Spinner from '../components/Spinner.jsx';

export default function ProductDetail() {
  const { slug } = useParams();
  const { addItem, items } = useCart();
  const [product, setProduct] = useState(null);
  const [error, setError] = useState('');
  const [qty, setQty] = useState(1);
  const [added, setAdded] = useState(false);

  useEffect(() => {
    setProduct(null);
    setError('');
    api(`/products/${slug}`).then(setProduct).catch((e) => setError(e.status === 404 ? 'Ce produit est introuvable.' : e.message));
  }, [slug]);

  if (error) {
    return (
      <div className="container page">
        <div className="empty"><h2>Oups…</h2><p>{error}</p><Link to="/produits" className="btn btn-primary">Retour au catalogue</Link></div>
      </div>
    );
  }
  if (!product) return <Spinner />;

  const inCart = items.find((i) => i.id === product.id)?.quantity || 0;
  const available = Math.max(0, product.stock - inCart);

  const onAdd = () => {
    addItem(product, qty);
    setAdded(true);
    setQty(1);
    setTimeout(() => setAdded(false), 2000);
  };

  return (
    <div className="container page">
      <nav className="breadcrumb" aria-label="Fil d'Ariane">
        <Link to="/">Accueil</Link> / <Link to={`/produits?category=${encodeURIComponent(product.category)}`}>{product.category}</Link> / <span>{product.name}</span>
      </nav>
      <div className="detail">
        <div className="detail-media card">
          <img src={product.imageUrl} alt={product.name} width="600" height="600" />
        </div>
        <div className="detail-info">
          <span className="product-cat">{product.category}</span>
          <h1>{product.name}</h1>
          <Rating value={product.rating} />
          <Price value={product.price} className="price-lg" />
          <p className="detail-desc">{product.description}</p>
          <p className={product.stock > 0 ? 'stock-ok' : 'stock-out'}>
            {product.stock > 0 ? `En stock (${product.stock} disponible${product.stock > 1 ? 's' : ''})` : 'Rupture de stock'}
          </p>
          {product.stock > 0 && (
            <div className="buy-row">
              <div className="qty">
                <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Diminuer">−</button>
                <span aria-live="polite">{qty}</span>
                <button type="button" onClick={() => setQty((q) => Math.min(available || 1, q + 1))} aria-label="Augmenter">+</button>
              </div>
              <button type="button" className="btn btn-primary btn-lg" onClick={onAdd} disabled={available <= 0}>
                {available <= 0 ? 'Quantité max. dans le panier' : 'Ajouter au panier'}
              </button>
            </div>
          )}
          {added && <p className="alert alert-success">Ajouté au panier ! <Link to="/panier">Voir le panier →</Link></p>}
          {inCart > 0 && !added && <p className="muted">Déjà {inCart} dans votre panier.</p>}
        </div>
      </div>
    </div>
  );
}
