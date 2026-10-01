import { useState } from 'react';

/** Affiche une note (lecture seule) ou permet de voter si onRate est fourni. */
export default function StarRating({ value = 0, onRate, size = 'md', label = 'Note', disabled = false }) {
  const [hover, setHover] = useState(0);
  const interactive = typeof onRate === 'function';
  const shown = hover || value;

  if (!interactive) {
    const pct = Math.max(0, Math.min(5, value)) * 20;
    return (
      <span className={`stars stars--${size}`} role="img" aria-label={`${label} : ${Number(value).toFixed(1)} sur 5`}>
        <span className="stars__bg">★★★★★</span>
        <span className="stars__fg" style={{ width: `${pct}%` }}>★★★★★</span>
      </span>
    );
  }

  return (
    <span className={`stars stars--${size} stars--interactive`} role="radiogroup" aria-label={label} onMouseLeave={() => setHover(0)}>
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          type="button"
          key={n}
          role="radio"
          aria-checked={value === n}
          aria-label={`${n} étoile${n > 1 ? 's' : ''}`}
          className={`star ${n <= shown ? 'star--on' : ''}`}
          onMouseEnter={() => setHover(n)}
          onFocus={() => setHover(n)}
          onBlur={() => setHover(0)}
          onClick={() => onRate(n)}
          disabled={disabled}
        >
          ★
        </button>
      ))}
    </span>
  );
}
