import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { api } from '../utils/api.js';
import ProductCard from '../components/ProductCard.jsx';
import Spinner from '../components/Spinner.jsx';

const SORTS = [
  ['newest', 'Nouveautés'],
  ['price_asc', 'Prix croissant'],
  ['price_desc', 'Prix décroissant'],
  ['rating', 'Mieux notés']
];

export default function Catalog() {
  const [params, setParams] = useSearchParams();
  const [data, setData] = useState(null);
  const [categories, setCategories] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState(params.get('search') || '');
  const [minPrice, setMinPrice] = useState(params.get('minPrice') || '');
  const [maxPrice, setMaxPrice] = useState(params.get('maxPrice') || '');

  const query = Object.fromEntries(params.entries());
  const key = params.toString();

  useEffect(() => {
    api('/categories').then(setCategories).catch(() => {});
  }, []);

  useEffect(() => {
    setSearch(params.get('search') || '');
    setMinPrice(params.get('minPrice') || '');
    setMaxPrice(params.get('maxPrice') || '');
    setData(null);
    setError('');
    api('/products', { query: { limit: 12, ...query } })
      .then(setData)
      .catch((e) => setError(e.message));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  const update = (patch) => {
    const next = new URLSearchParams(params);
    Object.entries(patch).forEach(([k, v]) => (v === '' || v == null ? next.delete(k) : next.set(k, v)));
    if (!('page' in patch)) next.delete('page');
    setParams(next);
  };

  const onSubmit = (e) => {
    e.preventDefault();
    update({ search: search.trim(), minPrice, maxPrice });
  };

  const page = Number(params.get('page') || 1);

  return (
    <div className="container page">
      <div className="page-head">
        <h1>Catalogue</h1>
        {data && <p className="muted">{data.total} produit{data.total > 1 ? 's' : ''}</p>}
      </div>

      <div className="catalog">
        <aside className="filters card">
          <form onSubmit={onSubmit}>
            <label className="field">
              <span>Recherche</span>
              <input type="search" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Nom, description…" />
            </label>
            <div className="field">
              <span>Catégorie</span>
              <div className="chips">
                <button type="button" className={`chip ${!params.get('category') ? 'chip-on' : ''}`} onClick={() => update({ category: '' })}>Toutes</button>
                {categories.map((c) => (
                  <button
                    key={c.name}
                    type="button"
                    className={`chip ${params.get('category') === c.name ? 'chip-on' : ''}`}
                    onClick={() => update({ category: c.name })}
                  >
                    {c.name}
                  </button>
                ))}
              </div>
            </div>
            <div className="field">
              <span>Prix (FCFA)</span>
              <div className="row-2">
                <input type="number" min="0" step="500" placeholder="Min" value={minPrice} onChange={(e) => setMinPrice(e.target.value)} aria-label="Prix minimum" />
                <input type="number" min="0" step="500" placeholder="Max" value={maxPrice} onChange={(e) => setMaxPrice(e.target.value)} aria-label="Prix maximum" />
              </div>
            </div>
            <div className="row-2">
              <button type="submit" className="btn btn-primary">Filtrer</button>
              <button type="button" className="btn btn-ghost" onClick={() => setParams(new URLSearchParams())}>Réinitialiser</button>
            </div>
          </form>
        </aside>

        <section>
          <div className="toolbar">
            <label className="sort">
              Trier par
              <select value={params.get('sort') || 'newest'} onChange={(e) => update({ sort: e.target.value })}>
                {SORTS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </label>
          </div>

          {error && <p className="alert alert-error">{error}</p>}
          {!data && !error && <Spinner />}
          {data && data.items.length === 0 && (
            <div className="empty">
              <h2>Aucun produit trouvé</h2>
              <p>Essayez d'élargir votre recherche ou de modifier les filtres.</p>
            </div>
          )}
          {data && data.items.length > 0 && (
            <>
              <div className="grid">{data.items.map((p) => <ProductCard key={p.id} product={p} />)}</div>
              {data.pages > 1 && (
                <nav className="pagination" aria-label="Pagination">
                  <button type="button" className="btn btn-ghost btn-sm" disabled={page <= 1} onClick={() => update({ page: page - 1 })}>← Précédent</button>
                  {Array.from({ length: data.pages }, (_, i) => i + 1).map((n) => (
                    <button key={n} type="button" className={`btn btn-sm ${n === page ? 'btn-primary' : 'btn-ghost'}`} onClick={() => update({ page: n })} aria-current={n === page ? 'page' : undefined}>{n}</button>
                  ))}
                  <button type="button" className="btn btn-ghost btn-sm" disabled={page >= data.pages} onClick={() => update({ page: page + 1 })}>Suivant →</button>
                </nav>
              )}
            </>
          )}
        </section>
      </div>
    </div>
  );
}
