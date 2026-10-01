import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../utils/api.js';
import ProductCard from '../components/ProductCard.jsx';
import Spinner from '../components/Spinner.jsx';

const CATEGORY_ICONS = { Mode: '👗', 'Électronique': '🎧', 'Épicerie': '🍯', Maison: '🏠', 'Beauté': '🌿' };

export default function Home() {
  const [featured, setFeatured] = useState(null);
  const [categories, setCategories] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    api('/products', { query: { sort: 'rating', limit: 8 } })
      .then((d) => setFeatured(d.items))
      .catch((e) => setError(e.message));
    api('/categories').then(setCategories).catch(() => {});
  }, []);

  return (
    <>
      <section className="hero">
        <div className="container hero-inner">
          <div>
            <span className="eyebrow">Made in Sénégal</span>
            <h1>Le meilleur du commerce local, livré chez vous.</h1>
            <p>Mode, épicerie fine, maison, beauté et high-tech : découvrez une sélection de produits choisis par des commerçants passionnés.</p>
            <div className="hero-actions">
              <Link to="/produits" className="btn btn-primary btn-lg">Voir le catalogue</Link>
              <Link to="/inscription" className="btn btn-ghost btn-lg">Créer un compte</Link>
            </div>
          </div>
          <div className="hero-visual" aria-hidden="true">
            <img src="https://picsum.photos/seed/boutik-hero/700/560" alt="" />
          </div>
        </div>
      </section>

      <section className="container section">
        <div className="features">
          <div><strong>🚚 Livraison rapide</strong><span>24–72 h à Dakar et en région</span></div>
          <div><strong>🔒 Paiement sécurisé</strong><span>Référence de paiement à chaque commande</span></div>
          <div><strong>💬 Service client</strong><span>Une équipe à votre écoute 7j/7</span></div>
        </div>
      </section>

      {categories.length > 0 && (
        <section className="container section">
          <h2 className="section-title">Catégories</h2>
          <div className="cat-grid">
            {categories.map((c) => (
              <Link key={c.name} to={`/produits?category=${encodeURIComponent(c.name)}`} className="cat-tile">
                <span className="cat-icon">{CATEGORY_ICONS[c.name] || '🛍️'}</span>
                <span className="cat-name">{c.name}</span>
                <span className="cat-count">{c.count} produit{c.count > 1 ? 's' : ''}</span>
              </Link>
            ))}
          </div>
        </section>
      )}

      <section className="container section">
        <div className="section-head">
          <h2 className="section-title">Les mieux notés</h2>
          <Link to="/produits" className="link">Tout voir →</Link>
        </div>
        {error && <p className="alert alert-error">{error}</p>}
        {!featured && !error ? <Spinner /> : (
          <div className="grid">{featured?.map((p) => <ProductCard key={p.id} product={p} />)}</div>
        )}
      </section>
    </>
  );
}
