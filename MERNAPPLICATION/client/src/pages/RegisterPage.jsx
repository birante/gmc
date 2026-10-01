import { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { useToast } from '../context/ToastContext.jsx';

export default function RegisterPage() {
  const { register, user } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from || '/dashboard';
  const [form, setForm] = useState({ name: '', email: '', password: '', confirm: '' });
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (user) return <Navigate to={from} replace />;

  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const onSubmit = async (e) => {
    e.preventDefault();
    if (form.name.trim().length < 2) return setError('Le nom doit contenir au moins 2 caractères.');
    if (!/^\S+@\S+\.\S+$/.test(form.email)) return setError('E-mail invalide.');
    if (form.password.length < 6) return setError('Le mot de passe doit contenir au moins 6 caractères.');
    if (form.password !== form.confirm) return setError('Les mots de passe ne correspondent pas.');
    setSubmitting(true);
    setError('');
    try {
      const u = await register({ name: form.name.trim(), email: form.email, password: form.password });
      showToast(`Bienvenue sur EventHub, ${u.name} !`);
      navigate(from, { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
    return undefined;
  };

  return (
    <section className="auth-page">
      <form className="card auth-card" onSubmit={onSubmit} noValidate>
        <h1>Créer un compte</h1>
        <p className="muted">Publiez vos événements et inscrivez-vous en un clic.</p>
        {error && <div className="alert alert-error" role="alert">{error}</div>}
        <div className="field">
          <label htmlFor="name">Nom complet</label>
          <input id="name" name="name" autoComplete="name" value={form.name} onChange={onChange} />
        </div>
        <div className="field">
          <label htmlFor="email">E-mail</label>
          <input id="email" name="email" type="email" autoComplete="email" value={form.email} onChange={onChange} />
        </div>
        <div className="field">
          <label htmlFor="password">Mot de passe</label>
          <input id="password" name="password" type="password" autoComplete="new-password" value={form.password} onChange={onChange} />
        </div>
        <div className="field">
          <label htmlFor="confirm">Confirmer le mot de passe</label>
          <input id="confirm" name="confirm" type="password" autoComplete="new-password" value={form.confirm} onChange={onChange} />
        </div>
        <button type="submit" className="btn btn-primary btn-block" disabled={submitting}>
          {submitting ? 'Création…' : 'Créer mon compte'}
        </button>
        <p className="auth-switch">
          Déjà inscrit ? <Link to="/login" state={location.state}>Se connecter</Link>
        </p>
      </form>
    </section>
  );
}
