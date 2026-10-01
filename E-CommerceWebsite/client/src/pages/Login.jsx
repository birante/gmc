import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const user = await login(email, password);
      navigate(location.state?.from || (user.role === 'admin' ? '/admin' : '/'), { replace: true });
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  };

  return (
    <div className="container page auth-page">
      <form className="card form auth-card" onSubmit={onSubmit}>
        <h1>Connexion</h1>
        <p className="muted">Heureux de vous revoir sur Boutik.</p>
        <label className="field"><span>Email</span><input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" /></label>
        <label className="field"><span>Mot de passe</span><input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required autoComplete="current-password" /></label>
        {error && <p className="alert alert-error" role="alert">{error}</p>}
        <button type="submit" className="btn btn-primary btn-block btn-lg" disabled={loading}>{loading ? 'Connexion…' : 'Se connecter'}</button>
        <p className="muted small">Pas encore de compte ? <Link to="/inscription" state={location.state}>Inscrivez-vous</Link></p>
        <p className="demo-hint small">Compte démo : <code>demo@boutik.sn</code> / <code>password123</code></p>
      </form>
    </div>
  );
}
