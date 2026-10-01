import { useState } from 'react';
import { Link } from 'react-router';
import { api } from '../api/client';
import type { ReminderMessage } from '../api/types';
import { ErrorMessage, Spinner } from '../components/Feedback';
import { StatusBadge } from '../components/StatusBadge';
import { useAsync } from '../hooks/useAsync';
import { formatDate, relativeDays } from '../lib/format';

export function WorklistPage() {
  const [status, setStatus] = useState<'DUE' | 'OVERDUE'>('DUE');
  const { data, error, loading } = useAsync(() => api.worklist(status), [status]);
  const [preview, setPreview] = useState<ReminderMessage[] | null>(null);
  const [result, setResult] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const loadPreview = async () => {
    setResult(null);
    setPreview((await api.reminderPreview()).data);
  };
  const send = async () => {
    setBusy(true);
    try {
      const { data: r } = await api.sendReminders();
      setResult(`${r.sent} of ${r.candidates} reminder(s) sent.`);
      setPreview(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Daily worklist</h1>
        <div className="flex gap-2">
          <button className="btn-secondary" onClick={loadPreview}>Preview SMS reminders</button>
        </div>
      </div>

      {result && <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{result}</div>}
      {preview && (
        <section className="card space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-semibold">{preview.length} reminder(s) ready</h2>
            <button className="btn-primary" disabled={busy || preview.length === 0} onClick={send}>Send now</button>
          </div>
          <ul className="max-h-64 space-y-2 overflow-y-auto text-sm">
            {preview.map((m) => (
              <li key={m.patientId} className="rounded-lg bg-slate-50 p-3"><span className="font-mono text-xs text-slate-500">{m.to}</span><p>{m.message}</p></li>
            ))}
          </ul>
        </section>
      )}

      <div className="flex gap-2" role="tablist">
        {(['DUE', 'OVERDUE'] as const).map((s) => (
          <button key={s} role="tab" aria-selected={status === s} className={status === s ? 'btn-primary' : 'btn-secondary'} onClick={() => setStatus(s)}>
            {s === 'DUE' ? 'Due in the next 7 days' : 'Overdue (defaulter tracing)'}
          </button>
        ))}
      </div>

      {error && <ErrorMessage message={error} />}
      {loading && <Spinner />}
      {data && !loading && (
        <div className="card overflow-x-auto p-0">
          <table className="min-w-full divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-50 text-left text-slate-600">
              <tr>
                <th className="px-4 py-3 font-medium">Date</th><th className="px-4 py-3 font-medium">Child</th>
                <th className="px-4 py-3 font-medium">Vaccine</th><th className="px-4 py-3 font-medium">Guardian</th>
                <th className="px-4 py-3 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.data.map((w) => (
                <tr key={w.id}>
                  <td className="px-4 py-3 tabular-nums">{formatDate(w.scheduledDate)} <span className="text-xs text-slate-400">{relativeDays(w.daysFromToday)}</span></td>
                  <td className="px-4 py-3"><Link className="text-brand-700 hover:underline" to={`/patients/${w.patient.id}`}>{w.patient.firstName} {w.patient.lastName}</Link></td>
                  <td className="px-4 py-3 font-medium">{w.vaccine.code}</td>
                  <td className="px-4 py-3">{w.patient.guardianName} <span className="text-slate-400">{w.patient.guardianPhone}</span></td>
                  <td className="px-4 py-3"><StatusBadge status={w.status} /></td>
                </tr>
              ))}
              {data.data.length === 0 && <tr><td colSpan={5} className="px-4 py-8 text-center text-slate-500">Nothing to show.</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
