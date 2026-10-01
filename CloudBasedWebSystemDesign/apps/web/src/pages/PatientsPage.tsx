import { useState } from 'react';
import { Link } from 'react-router';
import { api } from '../api/client';
import { ErrorMessage, Spinner } from '../components/Feedback';
import { useAsync } from '../hooks/useAsync';
import { formatDate } from '../lib/format';

export function PatientsPage() {
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const { data, error, loading } = useAsync(() => api.patients({ search: query, page }), [query, page]);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Patients</h1>
        <Link to="/patients/new" className="btn-primary">+ Register child</Link>
      </div>
      <form
        className="flex gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
          setQuery(search);
        }}
      >
        <input aria-label="Search patients" className="input max-w-md" placeholder="Name, card number or phone" value={search} onChange={(e) => setSearch(e.target.value)} />
        <button className="btn-secondary">Search</button>
      </form>
      {error && <ErrorMessage message={error} />}
      {loading && !data && <Spinner />}
      {data && (
        <div className="card overflow-x-auto p-0">
          <table className="min-w-full divide-y divide-slate-200 text-sm">
            <thead className="bg-slate-50 text-left text-slate-600">
              <tr>
                <th className="px-4 py-3 font-medium">Card</th>
                <th className="px-4 py-3 font-medium">Child</th>
                <th className="px-4 py-3 font-medium">Born</th>
                <th className="px-4 py-3 font-medium">Guardian</th>
                <th className="px-4 py-3 font-medium">Clinic</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.data.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 font-mono text-xs">{p.referenceCode}</td>
                  <td className="px-4 py-3">
                    <Link to={`/patients/${p.id}`} className="font-medium text-brand-700 hover:underline">{p.firstName} {p.lastName}</Link>
                  </td>
                  <td className="px-4 py-3">{formatDate(p.dateOfBirth)}</td>
                  <td className="px-4 py-3">{p.guardianName} <span className="text-slate-400">{p.guardianPhone}</span></td>
                  <td className="px-4 py-3">{p.clinic.name}</td>
                </tr>
              ))}
              {data.data.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-slate-500">No patients found.</td></tr>
              )}
            </tbody>
          </table>
          <div className="flex items-center justify-between border-t border-slate-200 px-4 py-3 text-sm text-slate-600">
            <span>{data.meta.total} patient(s)</span>
            <div className="flex gap-2">
              <button className="btn-secondary" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
              <button className="btn-secondary" disabled={page >= data.meta.totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
