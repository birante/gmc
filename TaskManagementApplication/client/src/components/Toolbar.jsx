import { SORT_OPTIONS, STATUS_LABELS } from '../utils/labels.js';

const TABS = [{ value: '', label: 'Toutes' }, ...Object.entries(STATUS_LABELS).map(([value, label]) => ({ value, label: value === 'done' ? 'Terminées' : label }))];

export default function Toolbar({ status, onStatus, search, onSearch, sort, onSort, counts }) {
  return (
    <div className="toolbar">
      <div className="tabs" role="tablist" aria-label="Filtrer par statut">
        {TABS.map((t) => (
          <button
            key={t.value || 'all'}
            type="button"
            role="tab"
            aria-selected={status === t.value}
            className={`tab${status === t.value ? ' active' : ''}`}
            onClick={() => onStatus(t.value)}
          >
            {t.label}
            {counts && <span className="tab-count">{t.value ? counts.byStatus[t.value] : counts.total}</span>}
          </button>
        ))}
      </div>
      <div className="toolbar-controls">
        <input
          type="search"
          className="search"
          placeholder="Rechercher par titre ou description…"
          aria-label="Rechercher"
          value={search}
          onChange={(e) => onSearch(e.target.value)}
        />
        <select className="sort" aria-label="Trier" value={sort} onChange={(e) => onSort(e.target.value)}>
          {SORT_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
      </div>
    </div>
  );
}
