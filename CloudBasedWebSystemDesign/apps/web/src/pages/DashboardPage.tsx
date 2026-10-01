import { useState } from 'react';
import { api } from '../api/client';
import { CoverageBar } from '../components/CoverageBar';
import { ErrorMessage, Spinner } from '../components/Feedback';
import { StatCard } from '../components/StatCard';
import { useAuth } from '../hooks/auth-context';
import { useAsync } from '../hooks/useAsync';

export function DashboardPage() {
  const { user } = useAuth();
  const [clinicId, setClinicId] = useState('');
  const clinics = useAsync(() => (user?.role === 'ADMIN' ? api.clinics() : Promise.resolve({ data: [] })), [user?.role]);
  const { data, error, loading } = useAsync(() => api.stats(clinicId || undefined), [clinicId]);

  const stats = data?.data;
  const maxMonthly = Math.max(1, ...(stats?.monthly.map((m) => m.count) ?? [1]));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Immunisation dashboard</h1>
          <p className="text-sm text-slate-500">{user?.role === 'ADMIN' ? 'All clinics' : user?.clinic?.name}</p>
        </div>
        {user?.role === 'ADMIN' && (
          <select aria-label="Filter by clinic" className="input w-64" value={clinicId} onChange={(e) => setClinicId(e.target.value)}>
            <option value="">All clinics</option>
            {clinics.data?.data.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        )}
      </div>

      {error && <ErrorMessage message={error} />}
      {loading && !stats && <Spinner />}
      {stats && (
        <>
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
            <StatCard label="Children followed" value={stats.totals.patients} />
            <StatCard label="Doses given (30 days)" value={stats.totals.administeredLast30Days} tone="success" />
            <StatCard label="Due this week" value={stats.totals.dueThisWeek} tone="warning" />
            <StatCard label="Overdue doses" value={stats.totals.overdue} tone="danger" />
            <StatCard
              label="Penta1-Penta3 dropout"
              value={`${stats.indicators.penta1To3Dropout}%`}
              hint="WHO alert threshold: 10%"
              tone={stats.indicators.penta1To3Dropout > 10 ? 'danger' : 'success'}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-3">
            <section className="card lg:col-span-2">
              <h2 className="mb-4 font-semibold">Coverage by dose (children old enough to have received it)</h2>
              <div className="grid gap-4 sm:grid-cols-2">
                {stats.coverage.map((c) => (
                  <CoverageBar key={c.vaccine.id} label={c.vaccine.code} value={c.coverage} administered={c.administered} eligible={c.eligible} />
                ))}
              </div>
            </section>
            <section className="card">
              <h2 className="mb-4 font-semibold">Doses given per month</h2>
              {stats.monthly.length === 0 && <p className="text-sm text-slate-500">No doses recorded yet.</p>}
              <ul className="space-y-2">
                {stats.monthly.map((m) => (
                  <li key={m.month} className="flex items-center gap-2 text-sm">
                    <span className="w-16 tabular-nums text-slate-500">{m.month}</span>
                    <span className="h-3 rounded bg-brand-600" style={{ width: `${(m.count / maxMonthly) * 70}%` }} />
                    <span className="tabular-nums">{m.count}</span>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        </>
      )}
    </div>
  );
}
