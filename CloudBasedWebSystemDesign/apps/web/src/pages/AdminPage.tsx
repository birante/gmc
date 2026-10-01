import { useState, type FormEvent } from 'react';
import { api } from '../api/client';
import { ErrorMessage, Spinner } from '../components/Feedback';
import { useAsync } from '../hooks/useAsync';

export function AdminPage() {
  const clinics = useAsync(() => api.clinics(), []);
  const users = useAsync(() => api.users(), []);
  const [clinic, setClinic] = useState({ code: '', name: '', region: '', district: '' });
  const [user, setUser] = useState({ name: '', email: '', password: '', role: 'CLINICIAN', clinicId: '' });
  const [error, setError] = useState<string | null>(null);

  const guard = async (fn: () => Promise<unknown>, after: () => void) => {
    setError(null);
    try {
      await fn();
      after();
    } catch (err) {
      setError((err as Error).message);
    }
  };

  const addClinic = (e: FormEvent) => {
    e.preventDefault();
    void guard(() => api.createClinic(clinic), () => {
      setClinic({ code: '', name: '', region: '', district: '' });
      clinics.reload();
    });
  };
  const addUser = (e: FormEvent) => {
    e.preventDefault();
    void guard(() => api.createUser({ ...user, clinicId: user.clinicId || null }), () => {
      setUser({ name: '', email: '', password: '', role: 'CLINICIAN', clinicId: '' });
      users.reload();
    });
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Administration</h1>
      {error && <ErrorMessage message={error} />}
      <div className="grid gap-6 lg:grid-cols-2">
        <section className="card space-y-4">
          <h2 className="font-semibold">Clinics</h2>
          {clinics.loading && <Spinner />}
          <ul className="divide-y divide-slate-100 text-sm">
            {clinics.data?.data.map((c) => (
              <li key={c.id} className="flex justify-between py-2">
                <span><span className="font-mono text-xs text-slate-500">{c.code}</span> {c.name}</span>
                <span className="text-slate-500">{c.district}, {c.region} · {c._count?.patients ?? 0} children</span>
              </li>
            ))}
          </ul>
          <form onSubmit={addClinic} className="grid grid-cols-2 gap-2">
            <input aria-label="Clinic code" required placeholder="Code (e.g. DKR-MEDINA)" className="input" value={clinic.code} onChange={(e) => setClinic({ ...clinic, code: e.target.value })} />
            <input aria-label="Clinic name" required placeholder="Name" className="input" value={clinic.name} onChange={(e) => setClinic({ ...clinic, name: e.target.value })} />
            <input aria-label="Region" required placeholder="Region" className="input" value={clinic.region} onChange={(e) => setClinic({ ...clinic, region: e.target.value })} />
            <input aria-label="District" required placeholder="District" className="input" value={clinic.district} onChange={(e) => setClinic({ ...clinic, district: e.target.value })} />
            <button className="btn-primary col-span-2">Add clinic</button>
          </form>
        </section>

        <section className="card space-y-4">
          <h2 className="font-semibold">Users</h2>
          {users.loading && <Spinner />}
          <ul className="divide-y divide-slate-100 text-sm">
            {users.data?.data.map((u) => (
              <li key={u.id} className="flex items-center justify-between py-2">
                <span>{u.name} <span className="text-slate-500">{u.email}</span></span>
                <span className="flex items-center gap-2">
                  <span className="text-xs text-slate-500">{u.role}{u.clinic ? ` · ${u.clinic.code}` : ''}</span>
                  <button
                    className={`text-xs ${u.active ? 'text-red-600' : 'text-emerald-600'} hover:underline`}
                    onClick={() => void guard(() => api.updateUser(u.id, { active: !u.active }), users.reload)}
                  >
                    {u.active ? 'Deactivate' : 'Activate'}
                  </button>
                </span>
              </li>
            ))}
          </ul>
          <form onSubmit={addUser} className="grid grid-cols-2 gap-2">
            <input aria-label="Full name" required placeholder="Full name" className="input" value={user.name} onChange={(e) => setUser({ ...user, name: e.target.value })} />
            <input aria-label="User email" required type="email" placeholder="Email" className="input" value={user.email} onChange={(e) => setUser({ ...user, email: e.target.value })} />
            <input aria-label="Initial password" required type="password" minLength={8} placeholder="Initial password" className="input" value={user.password} onChange={(e) => setUser({ ...user, password: e.target.value })} />
            <select aria-label="Role" className="input" value={user.role} onChange={(e) => setUser({ ...user, role: e.target.value })}>
              <option value="CLINICIAN">Clinician</option><option value="ADMIN">Administrator</option>
            </select>
            <select aria-label="User clinic" className="input col-span-2" value={user.clinicId} onChange={(e) => setUser({ ...user, clinicId: e.target.value })}>
              <option value="">No clinic (admins)</option>
              {clinics.data?.data.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
            <button className="btn-primary col-span-2">Add user</button>
          </form>
        </section>
      </div>
    </div>
  );
}
