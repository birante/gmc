import { useState } from 'react';
import { Link, useParams } from 'react-router';
import { api } from '../api/client';
import type { Dose } from '../api/types';
import { DoseTable } from '../components/DoseTable';
import { ErrorMessage, Spinner } from '../components/Feedback';
import { useAsync } from '../hooks/useAsync';
import { formatDate, todayISO } from '../lib/format';

export function PatientDetailPage() {
  const { id = '' } = useParams();
  const { data, error, loading, reload } = useAsync(() => api.patient(id), [id]);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const run = async (dose: Dose, action: () => Promise<unknown>) => {
    setBusyId(dose.id);
    setActionError(null);
    try {
      await action();
      reload();
    } catch (err) {
      setActionError((err as Error).message);
    } finally {
      setBusyId(null);
    }
  };

  const administer = (dose: Dose) => {
    const lotNumber = window.prompt(`Record ${dose.vaccine.code} given today (${formatDate(todayISO())}).\nLot number (optional):`, '');
    if (lotNumber === null) return;
    void run(dose, () => api.administer(dose.id, { administeredDate: todayISO(), ...(lotNumber ? { lotNumber } : {}) }));
  };
  const revert = (dose: Dose) => {
    if (window.confirm(`Undo ${dose.vaccine.code}?`)) void run(dose, () => api.revert(dose.id));
  };

  if (loading && !data) return <Spinner />;
  if (error) return <ErrorMessage message={error} />;
  if (!data) return null;
  const p = data.data;
  const pct = p.summary.total ? Math.round((p.summary.administered / p.summary.total) * 100) : 0;

  return (
    <div className="space-y-6">
      <Link to="/patients" className="text-sm text-brand-700 hover:underline">&larr; Patients</Link>
      <div className="grid gap-6 lg:grid-cols-3">
        <section className="card space-y-2">
          <h1 className="text-xl font-semibold">{p.firstName} {p.lastName}</h1>
          <p className="font-mono text-sm text-slate-500">{p.referenceCode}</p>
          <dl className="grid grid-cols-2 gap-y-1 text-sm">
            <dt className="text-slate-500">Born</dt><dd>{formatDate(p.dateOfBirth)} ({p.age})</dd>
            <dt className="text-slate-500">Sex</dt><dd>{p.sex === 'F' ? 'Female' : 'Male'}</dd>
            <dt className="text-slate-500">Guardian</dt><dd>{p.guardianName}</dd>
            <dt className="text-slate-500">Phone</dt><dd>{p.guardianPhone}</dd>
            <dt className="text-slate-500">Clinic</dt><dd>{p.clinic.name}</dd>
          </dl>
          <div className="pt-2">
            <div className="mb-1 flex justify-between text-sm"><span>Schedule completion</span><span>{pct}%</span></div>
            <div className="h-2 rounded-full bg-slate-100"><div className="h-2 rounded-full bg-brand-600" style={{ width: `${pct}%` }} /></div>
            <p className="mt-2 text-sm">
              <span className="text-red-600">{p.summary.overdue} overdue</span> · <span className="text-amber-600">{p.summary.due} due</span>
            </p>
          </div>
        </section>
        <section className="card lg:col-span-2">
          <h2 className="mb-3 font-semibold">Immunisation schedule</h2>
          {actionError && <ErrorMessage message={actionError} />}
          <DoseTable doses={p.immunizations} onAdminister={administer} onRevert={revert} busyId={busyId} />
        </section>
      </div>
    </div>
  );
}
