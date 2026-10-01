import type { DoseStatus } from '../api/types';

const STYLES: Record<DoseStatus, { label: string; className: string }> = {
  ADMINISTERED: { label: 'Given', className: 'bg-emerald-100 text-emerald-800 ring-emerald-600/20' },
  DUE: { label: 'Due', className: 'bg-amber-100 text-amber-800 ring-amber-600/20' },
  OVERDUE: { label: 'Overdue', className: 'bg-red-100 text-red-800 ring-red-600/20' },
  UPCOMING: { label: 'Upcoming', className: 'bg-slate-100 text-slate-700 ring-slate-500/20' },
};

export function StatusBadge({ status }: { status: DoseStatus }) {
  const { label, className } = STYLES[status];
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset ${className}`}>
      {label}
    </span>
  );
}
