import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function AuthPage({ mode }) {
  const isLogin = mode === 'login';
  const { login, register } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ name: '', email: '', password: '' });
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const onChange = (e) => setForm((f) => ({ ...f, [e.target.name]: e.target.value }));

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      if (isLogin) await login({ email: form.email, password: form.password });
      else await register(form);
      navigate('/', { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section className="auth-wrap">
      <div className="auth-intro">
        <h1>Organisez vos tâches,<br />respectez vos échéances.</h1>
        <p>TaskFlow vous aide à planifier votre travail, prioriser l’essentiel et suivre votre progression.</p>
        <ul className="auth-points">
          <li>Échéances et priorités claires</li>
          <li>Tâches en retard mises en évidence</li>
          <li>Barre de progression en temps réel</li>
        </ul>
      </div>
      <form className="card auth-card" onSubmit={onSubmit} noValidate>
        <h2>{isLogin ? 'Connexion' : 'Créer un compte'}</h2>
        {error && <div className="alert" role="alert">{error}</div>}
        {!isLogin && (
          <label className="field">
            <span>Nom</span>
            <input name="name" value={form.name} onChange={onChange} required minLength={2} autoComplete="name" />
          </label>
        )}
        <label className="field">
          <span>Email</span>
          <input name="email" type="email" value={form.email} onChange={onChange} required autoComplete="email" />
        </label>
        <label className="field">
          <span>Mot de passe</span>
          <input name="password" type="password" value={form.password} onChange={onChange} required minLength={6} autoComplete={isLogin ? 'current-password' : 'new-password'} />
        </label>
        <button type="submit" className="btn btn-primary btn-block" disabled={submitting}>
          {submitting ? 'Veuillez patienter…' : isLogin ? 'Se connecter' : 'S’inscrire'}
        </button>
        <p className="auth-switch">
          {isLogin ? (
            <>Pas encore de compte ? <Link to="/inscription">Inscrivez-vous</Link></>
          ) : (
            <>Déjà inscrit ? <Link to="/connexion">Connectez-vous</Link></>
          )}
        </p>
        {isLogin && <p className="demo-hint">Compte démo : <code>demo@taskflow.sn</code> / <code>password123</code></p>}
      </form>
    </section>
  );
}
