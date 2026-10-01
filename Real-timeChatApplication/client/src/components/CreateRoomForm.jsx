import { useState } from 'react';

export default function CreateRoomForm({ onCreate, onCancel }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    if (name.trim().length < 2) return setError('Le nom doit contenir au moins 2 caractères');
    setBusy(true);
    setError('');
    try {
      await onCreate({ name: name.trim(), description: description.trim() });
      setName('');
      setDescription('');
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <form className="create-room" onSubmit={submit}>
      <label>
        Nom du salon
        <input value={name} onChange={(e) => setName(e.target.value)} maxLength={40} placeholder="ex. Projet final" autoFocus />
      </label>
      <label>
        Description <span className="muted">(facultatif)</span>
        <input value={description} onChange={(e) => setDescription(e.target.value)} maxLength={200} placeholder="De quoi parle-t-on ici ?" />
      </label>
      {error && <p className="form-error" role="alert">{error}</p>}
      <div className="row">
        <button type="button" className="btn btn-ghost btn-sm" onClick={onCancel}>Annuler</button>
        <button type="submit" className="btn btn-primary btn-sm" disabled={busy}>{busy ? 'Création…' : 'Créer'}</button>
      </div>
    </form>
  );
}
