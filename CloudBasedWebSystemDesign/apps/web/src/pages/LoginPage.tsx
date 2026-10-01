import { useState, type FormEvent } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router';
import { ErrorMessage } from '../components/Feedback';
import { useAuth } from '../hooks/auth-context';

export function LoginPage() {
  const { user, login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (user) return <Navigate to="/" replace />;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await login(email, password);
      navigate((location.state as { from?: string } | null)?.from ?? '/', { replace: true });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-700 to-brand-800 px-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center text-white">
          <h1 className="text-3xl font-bold">VaxTrack</h1>
          <p className="mt-1 text-brand-100">Vaccination scheduling &amp; coverage monitoring</p>
        </div>
        <form onSubmit={submit} className="card space-y-4">
          <h2 className="text-lg font-semibold">Health worker sign in</h2>
          {error && <ErrorMessage message={error} />}
          <div>
            <label htmlFor="email" className="label">Email</label>
            <input id="email" type="email" autoComplete="username" required className="input" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <label htmlFor="password" className="label">Password</label>
            <input id="password" type="password" autoComplete="current-password" required className="input" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <button className="btn-primary w-full" disabled={busy}>{busy ? 'Signing in...' : 'Sign in'}</button>
          <p className="text-xs text-slate-500">
            Demo: <code>infirmier.yoff@vaxtrack.sn</code> / <code>Demo!2026</code>
          </p>
        </form>
        <p className="text-center text-sm text-brand-100">
          Parent or guardian? <Link to="/lookup" className="font-semibold text-white underline">Check your child&apos;s schedule</Link>
        </p>
      </div>
    </div>
  );
}
