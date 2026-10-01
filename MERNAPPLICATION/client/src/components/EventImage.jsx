import { useState } from 'react';
import { CATEGORY_ICONS } from '../utils/format.js';

export default function EventImage({ src, alt, category, className = '' }) {
  const [failed, setFailed] = useState(false);
  return (
    <div className={`event-image ${className}`.trim()}>
      {src && !failed ? (
        <img src={src} alt={alt} loading="lazy" onError={() => setFailed(true)} />
      ) : (
        <div className="event-image-fallback" aria-hidden="true">
          {CATEGORY_ICONS[category] || '🎟️'}
        </div>
      )}
    </div>
  );
}
