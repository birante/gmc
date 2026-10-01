import { useState } from 'react';

const PALETTE = ['#7a2e2e', '#2f4a3a', '#5b3a29', '#3a4560', '#6b4f1d', '#4d2d4f'];

function hash(str = '') {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) | 0;
  return Math.abs(h);
}

/** Couverture du livre, avec une couverture « reliée » générée si l'image manque. */
export default function BookCover({ book, size = 'md' }) {
  const [failed, setFailed] = useState(false);
  const title = book?.title || 'Livre';
  if (book?.coverUrl && !failed) {
    return (
      <img
        className={`cover cover--${size}`}
        src={book.coverUrl}
        alt={`Couverture de ${title}`}
        loading="lazy"
        onError={() => setFailed(true)}
        onLoad={(e) => {
          // Open Library renvoie une image 1x1 quand la couverture n'existe pas
          if (e.currentTarget.naturalWidth < 10) setFailed(true);
        }}
      />
    );
  }
  const color = PALETTE[hash(title) % PALETTE.length];
  return (
    <div className={`cover cover--${size} cover--placeholder`} style={{ '--cover': color }} role="img" aria-label={`Couverture de ${title}`}>
      <span className="cover__title">{title}</span>
      {book?.authors?.[0] && <span className="cover__author">{book.authors[0]}</span>}
    </div>
  );
}
