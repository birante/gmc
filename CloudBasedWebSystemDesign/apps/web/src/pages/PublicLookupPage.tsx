import { useState } from 'react';
import { Link } from 'react-router';
import { api } from '../api/client';
import type { PublicLookup } from '../api/types';
import { ErrorMessage } from '../components/Feedback';
import { LookupForm } from '../components/LookupForm';
import { StatusBadge } from '../components/StatusBadge';
import { formatDate } from '../lib/format';

export function PublicLookupPage() {
  const [result, setResult] = useState<PublicLookup | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const search = async (code: string, last4: string) => {
    setBusy(true);
    setError(null);
    try {
      setResult((await api.publicLookup(code, last4)).data);
    } catch (err) {
      setResult(null);
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-brand-50 px-4 py-10">
      <div className="mx-auto max-w-xl space-y-6">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-brand-800">VaxTrack</h1>
          <p className="text-slate-600">Check your child&apos;s vaccination schedule</p>
        </div>
        <div className="card"><LookupForm onSubmit={search} busy={busy} /></div>
        {error && <ErrorMessage message={error} />}
        {result && (
          <div className="card space-y-4">
            <div>
              <h2 className="text-lg font-semibold">{result.child}</h2>
              <p className="text-sm text-slate-500">{result.age} · {result.clinic.name} ({result.clinic.district})</p>
            </div>
            {result.nextDose && (
              <div className="rounded-lg bg-amber-50 p-4 text-amber-900">
                <p className="text-sm">Next vaccination</p>
                <p className="text-lg font-semibold">{result.nextDose.name} - {formatDate(result.nextDose.scheduledDate)}</p>
              </div>
            )}
            <ul className="divide-y divide-slate-100 text-sm">
              {result.doses.map((d) => (
                <li key={d.code} className="flex items-center justify-between py-2">
                  <span>{d.name}</span>
                  <span className="flex items-center gap-2 tabular-nums">{formatDate(d.administeredDate ?? d.scheduledDate)} <StatusBadge status={d.status} /></span>
                </li>
              ))}
            </ul>
          </div>
        )}
        <p className="text-center text-sm"><Link to="/login" className="text-brand-700 hover:underline">Health worker sign in</Link></p>
      </div>
    </div>
  );
}
