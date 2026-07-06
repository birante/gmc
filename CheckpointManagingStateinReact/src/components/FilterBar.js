import React from "react";

const FILTERS = [
  { value: "all", label: "All" },
  { value: "active", label: "Active" },
  { value: "completed", label: "Completed" },
];

// Segmented control that switches which subset of tasks is shown.
function FilterBar({ value, onChange, counts }) {
  return (
    <div className="filter" role="tablist" aria-label="Task filter">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          type="button"
          role="tab"
          aria-selected={value === f.value}
          className={`filter__btn ${
            value === f.value ? "filter__btn--active" : ""
          }`}
          onClick={() => onChange(f.value)}
        >
          {f.label} ({counts[f.value]})
        </button>
      ))}
    </div>
  );
}

export default FilterBar;
