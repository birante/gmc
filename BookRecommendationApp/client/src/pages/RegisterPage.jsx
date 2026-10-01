import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import GenrePicker from '../components/GenrePicker.jsx';
import { useAuth } from '../context/AuthContext.jsx';

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ username: '', email: '', password: '' });
  const [genres, setGenres] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      await register({ ...form, favoriteGenres: genres });
      navigate('/', { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-card auth-card--wide">
      <h1>Rejoindre BookNest</h1>
      <p className="muted">Créez votre étagère et partagez vos lectures.</p>
      <form onSubmit={submit} className="form">
        <div className="form-row">
          <label>
            Nom d'utilisateur
            <input value={form.username} onChange={set('username')} required minLength={3} maxLength={30} pattern="[a-zA-Z0-9_.\-]{3,30}" autoComplete="username" />
          </label>
          <label>
            Email
            <input type="email" value={form.email} onChange={set('email')} required autoComplete="email" />
          </label>
        </div>
        <label>
          Mot de passe <span className="muted small">(6 caractères minimum)</span>
          <input type="password" value={form.password} onChange={set('password')} required minLength={6} autoComplete="new-password" />
        </label>
        <GenrePicker value={genres} onChange={setGenres} label="Vos genres préférés (pour personnaliser le fil)" />
        {error && <p className="error" role="alert">{error}</p>}
        <button className="btn btn--primary btn--block" disabled={busy}>{busy ? 'Création…' : 'Créer mon compte'}</button>
      </form>
      <p className="small">Déjà inscrit ? <Link to="/connexion">Connectez-vous</Link></p>
    </div>
  );
}
