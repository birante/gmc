import { useState } from 'react';
import { PRIORITY_LABELS, STATUS_LABELS, fromDateInput, toDateInput } from '../utils/labels.js';

export default function TaskForm({ initial, onSubmit, onCancel }) {
  const [form, setForm] = useState({
    title: initial?.title || '',
    description: initial?.description || '',
    deadline: toDateInput(initial?.deadline),
    priority: initial?.priority || 'medium',
    status: initial?.status || 'todo',
  });
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) {
      setError('Le titre est requis');
      return;
    }
    setError('');
    setSubmitting(true);
    try {
      await onSubmit({ ...form, title: form.title.trim(), deadline: fromDateInput(form.deadline) });
    } catch (err) {
      setError(err.message);
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={submit} className="task-form" noValidate>
      {error && <div className="alert" role="alert">{error}</div>}
      <label className="field">
        <span>Titre *</span>
        <input name="title" value={form.title} onChange={onChange} maxLength={200} autoFocus placeholder="Ex. Préparer la réunion" />
      </label>
      <label className="field">
        <span>Description</span>
        <textarea name="description" value={form.description} onChange={onChange} rows={3} maxLength={5000} placeholder="Détails, étapes, liens…" />
      </label>
      <div className="form-row">
        <label className="field">
          <span>Échéance</span>
          <input name="deadline" type="date" value={form.deadline} onChange={onChange} />
        </label>
        <label className="field">
          <span>Priorité</span>
          <select name="priority" value={form.priority} onChange={onChange}>
            {Object.entries(PRIORITY_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select>
        </label>
        <label className="field">
          <span>Statut</span>
          <select name="status" value={form.status} onChange={onChange}>
            {Object.entries(STATUS_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select>
        </label>
      </div>
      <div className="form-actions">
        <button type="button" className="btn btn-ghost" onClick={onCancel}>Annuler</button>
        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting ? 'Enregistrement…' : initial ? 'Enregistrer' : 'Créer la tâche'}
        </button>
      </div>
    </form>
  );
}
