import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function Register() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [form, setForm] = useState({ name: '', email: '', password: '', confirm: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (form.password !== form.confirm) return setError('Les mots de passe ne correspondent pas');
    setLoading(true);
    try {
      await register(form.name, form.email, form.password);
      navigate(location.state?.from || '/', { replace: true });
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  };

  return (
    <div className="container page auth-page">
      <form className="card form auth-card" onSubmit={onSubmit}>
        <h1>Créer un compte</h1>
        <p className="muted">Inscrivez-vous pour commander et suivre vos achats.</p>
        <label className="field"><span>Nom complet</span><input name="name" value={form.name} onChange={onChange} required minLength={2} autoComplete="name" /></label>
        <label className="field"><span>Email</span><input name="email" type="email" value={form.email} onChange={onChange} required autoComplete="email" /></label>
        <label className="field"><span>Mot de passe</span><input name="password" type="password" value={form.password} onChange={onChange} required minLength={6} autoComplete="new-password" /></label>
        <label className="field"><span>Confirmer le mot de passe</span><input name="confirm" type="password" value={form.confirm} onChange={onChange} required minLength={6} autoComplete="new-password" /></label>
        {error && <p className="alert alert-error" role="alert">{error}</p>}
        <button type="submit" className="btn btn-primary btn-block btn-lg" disabled={loading}>{loading ? 'Création…' : "S'inscrire"}</button>
        <p className="muted small">Déjà inscrit ? <Link to="/connexion" state={location.state}>Connectez-vous</Link></p>
      </form>
    </div>
  );
}
