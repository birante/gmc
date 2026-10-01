import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import AuthLayout from './AuthLayout.jsx';

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ username: '', email: '', password: '', confirm: '' });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    if (form.username.trim().length < 2) return setError("Le nom d'utilisateur doit contenir au moins 2 caractères");
    if (form.password.length < 6) return setError('Le mot de passe doit contenir au moins 6 caractères');
    if (form.password !== form.confirm) return setError('Les mots de passe ne correspondent pas');
    setBusy(true);
    setError('');
    try {
      await register(form.username.trim(), form.email.trim(), form.password);
      navigate('/', { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthLayout title="Créer un compte" subtitle="Rejoignez la conversation en quelques secondes.">
      <form className="form" onSubmit={submit} noValidate>
        <label>
          Nom d'utilisateur
          <input autoComplete="username" value={form.username} onChange={set('username')} maxLength={30} required />
        </label>
        <label>
          Email
          <input type="email" autoComplete="email" value={form.email} onChange={set('email')} required />
        </label>
        <label>
          Mot de passe
          <input type="password" autoComplete="new-password" value={form.password} onChange={set('password')} required />
        </label>
        <label>
          Confirmer le mot de passe
          <input type="password" autoComplete="new-password" value={form.confirm} onChange={set('confirm')} required />
        </label>
        {error && <p className="form-error" role="alert">{error}</p>}
        <button type="submit" className="btn btn-primary btn-block" disabled={busy}>{busy ? 'Création…' : "S'inscrire"}</button>
      </form>
      <p className="auth-switch">Déjà inscrit ? <Link to="/connexion">Se connecter</Link></p>
    </AuthLayout>
  );
}
