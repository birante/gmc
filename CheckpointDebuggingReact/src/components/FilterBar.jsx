const FILTERS = [
  { key: "all", label: "All" },
  { key: "done", label: "Done" },
  { key: "notDone", label: "Not done" },
];

export default function FilterBar({ filter, onChange }) {
  return (
    <div className="filters" role="tablist">
      {FILTERS.map((f) => (
        <button
          key={f.key}
          type="button"
          role="tab"
          aria-selected={filter === f.key}
          className={filter === f.key ? "active" : ""}
          onClick={() => onChange(f.key)}
        >
          {f.label}
        </button>
      ))}
    </div>
  );
}
