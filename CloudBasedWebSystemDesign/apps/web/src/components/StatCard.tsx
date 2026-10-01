interface Props {
  label: string;
  value: string | number;
  hint?: string;
  tone?: 'default' | 'warning' | 'danger' | 'success';
}

const TONES = {
  default: 'text-slate-900',
  warning: 'text-amber-600',
  danger: 'text-red-600',
  success: 'text-emerald-600',
};

export function StatCard({ label, value, hint, tone = 'default' }: Props) {
  return (
    <div className="card">
      <p className="text-sm text-slate-500">{label}</p>
      <p className={`mt-1 text-3xl font-semibold tabular-nums ${TONES[tone]}`}>{value}</p>
      {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
    </div>
  );
}
