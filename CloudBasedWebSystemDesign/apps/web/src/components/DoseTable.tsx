import type { Dose } from '../api/types';
import { formatDate } from '../lib/format';
import { StatusBadge } from './StatusBadge';

interface Props {
  doses: Dose[];
  onAdminister?: (dose: Dose) => void;
  onRevert?: (dose: Dose) => void;
  busyId?: string | null;
}

export function DoseTable({ doses, onAdminister, onRevert, busyId }: Props) {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="text-left text-slate-600">
          <tr>
            <th className="py-2 pr-4 font-medium">Vaccine</th>
            <th className="py-2 pr-4 font-medium">Scheduled</th>
            <th className="py-2 pr-4 font-medium">Given</th>
            <th className="py-2 pr-4 font-medium">Status</th>
            <th className="py-2 font-medium"><span className="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {doses.map((d) => (
            <tr key={d.id}>
              <td className="py-2 pr-4"><span className="font-medium">{d.vaccine.code}</span> <span className="text-slate-500">{d.vaccine.name}</span></td>
              <td className="py-2 pr-4 tabular-nums">{formatDate(d.scheduledDate)}</td>
              <td className="py-2 pr-4 tabular-nums">
                {formatDate(d.administeredDate)}
                {d.lotNumber && <span className="ml-1 text-xs text-slate-400">lot {d.lotNumber}</span>}
              </td>
              <td className="py-2 pr-4"><StatusBadge status={d.status} /></td>
              <td className="py-2 text-right">
                {d.status !== 'ADMINISTERED' && onAdminister && (
                  <button className="btn-primary px-3 py-1" disabled={busyId === d.id} onClick={() => onAdminister(d)}>Record dose</button>
                )}
                {d.status === 'ADMINISTERED' && onRevert && (
                  <button className="text-xs text-slate-500 hover:text-red-600" disabled={busyId === d.id} onClick={() => onRevert(d)}>Undo</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
