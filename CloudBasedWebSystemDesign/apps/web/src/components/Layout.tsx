import { NavLink, Outlet } from 'react-router';
import { useAuth } from '../hooks/auth-context';

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `rounded-md px-3 py-2 text-sm font-medium ${isActive ? 'bg-brand-800 text-white' : 'text-brand-50 hover:bg-brand-600'}`;

export function Layout() {
  const { user, logout } = useAuth();
  return (
    <div className="min-h-screen">
      <header className="bg-brand-700">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-3 px-4 py-3">
          <div className="flex items-center gap-6">
            <NavLink to="/" className="text-lg font-bold text-white">VaxTrack</NavLink>
            <nav className="flex flex-wrap gap-1" aria-label="Main">
              <NavLink to="/" end className={linkClass}>Dashboard</NavLink>
              <NavLink to="/patients" className={linkClass}>Patients</NavLink>
              <NavLink to="/worklist" className={linkClass}>Worklist</NavLink>
              {user?.role === 'ADMIN' && <NavLink to="/admin" className={linkClass}>Admin</NavLink>}
            </nav>
          </div>
          <div className="flex items-center gap-3 text-sm text-brand-50">
            <span>
              {user?.name} <span className="opacity-75">· {user?.role === 'ADMIN' ? 'Administrator' : user?.clinic?.name}</span>
            </span>
            <button onClick={logout} className="rounded-md border border-brand-50/40 px-3 py-1 hover:bg-brand-600">Sign out</button>
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-7xl px-4 py-6">
        <Outlet />
      </main>
    </div>
  );
}
