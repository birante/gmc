import { Link } from 'react-router-dom';
import { useCart } from '../context/CartContext.jsx';
import Price from './Price.jsx';
import Rating from './Rating.jsx';

export default function ProductCard({ product }) {
  const { addItem } = useCart();
  const out = product.stock <= 0;
  return (
    <article className="card product-card">
      <Link to={`/produits/${product.slug}`} className="product-media">
        <img src={product.imageUrl} alt={product.name} loading="lazy" width="600" height="600" />
        {out && <span className="ribbon">Rupture</span>}
        {!out && product.stock <= 5 && <span className="ribbon ribbon-warn">Plus que {product.stock}</span>}
      </Link>
      <div className="product-body">
        <span className="product-cat">{product.category}</span>
        <h3 className="product-name">
          <Link to={`/produits/${product.slug}`}>{product.name}</Link>
        </h3>
        <Rating value={product.rating} />
        <div className="product-foot">
          <Price value={product.price} />
          <button
            type="button"
            className="btn btn-primary btn-sm"
            onClick={() => addItem(product)}
            disabled={out}
            aria-label={`Ajouter ${product.name} au panier`}
          >
            {out ? 'Épuisé' : 'Ajouter'}
          </button>
        </div>
      </div>
    </article>
  );
}
