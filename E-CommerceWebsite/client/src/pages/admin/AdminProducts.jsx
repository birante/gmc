import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../../utils/api.js';
import Price from '../../components/Price.jsx';
import Spinner from '../../components/Spinner.jsx';
import AdminNav from './AdminNav.jsx';
import ProductForm from './ProductForm.jsx';

export default function AdminProducts() {
  const [products, setProducts] = useState(null);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(null); // null | 'new' | product
  const [search, setSearch] = useState('');

  const load = useCallback(() => {
    api('/products', { query: { limit: 100, sort: 'newest', search } })
      .then((d) => setProducts(d.items))
      .catch((e) => setError(e.message));
  }, [search]);

  useEffect(() => { load(); }, [load]);

  const categories = [...new Set((products || []).map((p) => p.category))].sort();

  const save = async (payload) => {
    if (editing === 'new') await api('/products', { method: 'POST', body: payload });
    else await api(`/products/${editing.id}`, { method: 'PUT', body: payload });
    setEditing(null);
    load();
  };

  const remove = async (p) => {
    if (!window.confirm(`Supprimer « ${p.name} » ?`)) return;
    try {
      await api(`/products/${p.id}`, { method: 'DELETE' });
      load();
    } catch (e) {
      setError(e.message);
    }
  };

  return (
    <div className="container page">
      <div className="page-head">
        <h1>Administration</h1>
        <button type="button" className="btn btn-primary" onClick={() => setEditing('new')}>+ Nouveau produit</button>
      </div>
      <AdminNav />
      <div className="toolbar">
        <input type="search" className="input" placeholder="Filtrer les produits…" value={search} onChange={(e) => setSearch(e.target.value)} aria-label="Filtrer les produits" />
      </div>
      {error && <p className="alert alert-error">{error}</p>}
      {!products ? <Spinner /> : (
        <div className="card table-wrap">
          <table className="table">
            <thead><tr><th>Produit</th><th>Catégorie</th><th>Prix</th><th>Stock</th><th aria-label="Actions" /></tr></thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td className="cell-product"><img src={p.imageUrl} alt="" width="40" height="40" /><Link to={`/produits/${p.slug}`}>{p.name}</Link></td>
                  <td>{p.category}</td>
                  <td><Price value={p.price} /></td>
                  <td><span className={p.stock === 0 ? 'stock-out' : p.stock <= 5 ? 'stock-low' : ''}>{p.stock}</span></td>
                  <td className="cell-actions">
                    <button type="button" className="btn btn-ghost btn-sm" onClick={() => setEditing(p)}>Modifier</button>
                    <button type="button" className="btn btn-danger btn-sm" onClick={() => remove(p)}>Supprimer</button>
                  </td>
                </tr>
              ))}
              {products.length === 0 && <tr><td colSpan="5" className="muted">Aucun produit.</td></tr>}
            </tbody>
          </table>
        </div>
      )}

      {editing && (
        <div className="modal-backdrop" role="dialog" aria-modal="true" aria-label={editing === 'new' ? 'Nouveau produit' : 'Modifier le produit'} onClick={(e) => e.target === e.currentTarget && setEditing(null)}>
          <div className="modal card">
            <h2>{editing === 'new' ? 'Nouveau produit' : `Modifier « ${editing.name} »`}</h2>
            <ProductForm initial={editing === 'new' ? null : editing} categories={categories} onSubmit={save} onCancel={() => setEditing(null)} />
          </div>
        </div>
      )}
    </div>
  );
}
