import { useState } from 'react';

const EMPTY = { name: '', category: '', price: '', stock: '', description: '', imageUrl: '', rating: '' };

export default function ProductForm({ initial, categories = [], onSubmit, onCancel }) {
  const [form, setForm] = useState(() => (initial ? { ...EMPTY, ...initial } : EMPTY));
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setSaving(true);
    const payload = {
      name: form.name,
      category: form.category,
      price: Number(form.price),
      stock: Number(form.stock),
      description: form.description,
      imageUrl: form.imageUrl
    };
    if (form.rating !== '' && form.rating != null) payload.rating = Number(form.rating);
    try {
      await onSubmit(payload);
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  };

  return (
    <form className="form" onSubmit={submit}>
      <label className="field"><span>Nom</span><input name="name" value={form.name} onChange={onChange} required minLength={2} /></label>
      <div className="row-2">
        <label className="field">
          <span>Catégorie</span>
          <input name="category" value={form.category} onChange={onChange} required list="admin-categories" />
          <datalist id="admin-categories">{categories.map((c) => <option key={c} value={c} />)}</datalist>
        </label>
        <label className="field"><span>Note (0–5)</span><input name="rating" type="number" min="0" max="5" step="0.1" value={form.rating} onChange={onChange} /></label>
      </div>
      <div className="row-2">
        <label className="field"><span>Prix (FCFA)</span><input name="price" type="number" min="0" step="1" value={form.price} onChange={onChange} required /></label>
        <label className="field"><span>Stock</span><input name="stock" type="number" min="0" step="1" value={form.stock} onChange={onChange} required /></label>
      </div>
      <label className="field"><span>URL de l'image (optionnel)</span><input name="imageUrl" type="url" value={form.imageUrl} onChange={onChange} placeholder="https://…" /></label>
      <label className="field"><span>Description</span><textarea name="description" rows="4" value={form.description} onChange={onChange} /></label>
      {error && <p className="alert alert-error" role="alert">{error}</p>}
      <div className="row-2">
        <button type="button" className="btn btn-ghost" onClick={onCancel}>Annuler</button>
        <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Enregistrement…' : 'Enregistrer'}</button>
      </div>
    </form>
  );
}
