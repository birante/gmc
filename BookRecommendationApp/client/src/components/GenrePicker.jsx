import { useState } from 'react';
import { SUGGESTED_GENRES } from '../utils.js';

export default function GenrePicker({ value, onChange, label = 'Genres favoris' }) {
  const [custom, setCustom] = useState('');
  const options = [...new Set([...SUGGESTED_GENRES, ...value])];
  const toggle = (g) => onChange(value.includes(g) ? value.filter((x) => x !== g) : [...value, g]);
  return (
    <fieldset className="genre-picker">
      <legend>{label}</legend>
      <div className="chips">
        {options.map((g) => (
          <button type="button" key={g} className={`chip ${value.includes(g) ? 'chip--on' : ''}`} aria-pressed={value.includes(g)} onClick={() => toggle(g)}>
            {g}
          </button>
        ))}
      </div>
      <div className="inline-add">
        <input
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
          placeholder="Autre genre…"
          aria-label="Ajouter un genre"
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (custom.trim()) onChange([...new Set([...value, custom.trim()])]);
              setCustom('');
            }
          }}
        />
      </div>
    </fieldset>
  );
}
