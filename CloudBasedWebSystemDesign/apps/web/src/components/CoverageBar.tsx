interface Props {
  label: string;
  value: number;
  administered: number;
  eligible: number;
  /** WHO/Gavi programme target, 90% national coverage for most antigens. */
  target?: number;
}

export function CoverageBar({ label, value, administered, eligible, target = 90 }: Props) {
  const color = value >= target ? 'bg-emerald-500' : value >= 80 ? 'bg-amber-500' : 'bg-red-500';
  return (
    <div className="space-y-1">
      <div className="flex justify-between text-sm">
        <span className="font-medium text-slate-700">{label}</span>
        <span className="tabular-nums text-slate-600">
          {value.toFixed(1)}% <span className="text-slate-400">({administered}/{eligible})</span>
        </span>
      </div>
      <div
        className="relative h-2.5 rounded-full bg-slate-100"
        role="progressbar"
        aria-label={`${label} coverage`}
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div className={`h-2.5 rounded-full ${color}`} style={{ width: `${Math.min(value, 100)}%` }} />
        <div className="absolute top-[-3px] h-4 w-0.5 bg-slate-500" style={{ left: `${target}%` }} title={`Target ${target}%`} />
      </div>
    </div>
  );
}
