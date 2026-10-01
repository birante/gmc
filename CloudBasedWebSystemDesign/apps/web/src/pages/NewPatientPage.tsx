import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router';
import { api, ApiError } from '../api/client';
import { ErrorMessage } from '../components/Feedback';
import { useAuth } from '../hooks/auth-context';
import { useAsync } from '../hooks/useAsync';
import { todayISO } from '../lib/format';

const EMPTY = { firstName: '', lastName: '', sex: 'F', dateOfBirth: '', guardianName: '', guardianPhone: '+221', address: '', clinicId: '' };

export function NewPatientPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState(EMPTY);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const clinics = useAsync(() => (user?.role === 'ADMIN' ? api.clinics() : Promise.resolve({ data: [] })), [user?.role]);

  const set = (key: keyof typeof EMPTY) => (e: { target: { value: string } }) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const { clinicId, address, ...rest } = form;
      const { data } = await api.createPatient({ ...rest, ...(address ? { address } : {}), ...(clinicId ? { clinicId } : {}) });
      navigate(`/patients/${data.id}`);
    } catch (err) {
      const details = err instanceof ApiError && err.details ? `: ${err.details.map((d) => `${d.path} ${d.message}`).join('; ')}` : '';
      setError(`${(err as Error).message}${details}`);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      <h1 className="text-2xl font-semibold">Register a child</h1>
      <p className="text-sm text-slate-500">The full national immunisation schedule is generated automatically from the date of birth.</p>
      <form onSubmit={submit} className="card grid gap-4 sm:grid-cols-2">
        {error && <div className="sm:col-span-2"><ErrorMessage message={error} /></div>}
        <div><label className="label" htmlFor="firstName">First name</label><input id="firstName" required className="input" value={form.firstName} onChange={set('firstName')} /></div>
        <div><label className="label" htmlFor="lastName">Last name</label><input id="lastName" required className="input" value={form.lastName} onChange={set('lastName')} /></div>
        <div>
          <label className="label" htmlFor="sex">Sex</label>
          <select id="sex" className="input" value={form.sex} onChange={set('sex')}><option value="F">Female</option><option value="M">Male</option></select>
        </div>
        <div><label className="label" htmlFor="dob">Date of birth</label><input id="dob" type="date" required max={todayISO()} className="input" value={form.dateOfBirth} onChange={set('dateOfBirth')} /></div>
        <div><label className="label" htmlFor="guardianName">Guardian name</label><input id="guardianName" required className="input" value={form.guardianName} onChange={set('guardianName')} /></div>
        <div><label className="label" htmlFor="guardianPhone">Guardian phone (SMS reminders)</label><input id="guardianPhone" type="tel" required className="input" value={form.guardianPhone} onChange={set('guardianPhone')} /></div>
        <div className="sm:col-span-2"><label className="label" htmlFor="address">Address / neighbourhood</label><input id="address" className="input" value={form.address} onChange={set('address')} /></div>
        {user?.role === 'ADMIN' && (
          <div className="sm:col-span-2">
            <label className="label" htmlFor="clinic">Clinic</label>
            <select id="clinic" required className="input" value={form.clinicId} onChange={set('clinicId')}>
              <option value="">Select a clinic</option>
              {clinics.data?.data.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
        )}
        <div className="flex justify-end gap-2 sm:col-span-2">
          <button type="button" className="btn-secondary" onClick={() => navigate(-1)}>Cancel</button>
          <button className="btn-primary" disabled={busy}>{busy ? 'Saving...' : 'Register'}</button>
        </div>
      </form>
    </div>
  );
}
