import { Link } from 'react-router-dom';
import { authorsLabel } from '../utils.js';
import BookCover from './BookCover.jsx';
import StarRating from './StarRating.jsx';

/** Lien vers la fiche locale ; null pour un résultat externe pas encore importé. */
export function bookLink(book) {
  return book.id ? `/livres/${book.id}` : null;
}

export default function BookTile({ book, actions }) {
  const href = bookLink(book);
  const external = !book.id && book.source === 'openlibrary';
  return (
    <article className={`book-tile ${external ? 'book-tile--external' : ''}`}>
      {href ? (
        <Link to={href} className="book-tile__cover">
          <BookCover book={book} />
        </Link>
      ) : (
        <div className="book-tile__cover">
          <BookCover book={book} />
        </div>
      )}
      <div className="book-tile__info">
        {external && <span className="source-badge">Open Library</span>}
        <h3>{href ? <Link to={href}>{book.title}</Link> : book.title}</h3>
        <p className="muted small">{authorsLabel(book.authors)}</p>
        {book.ratingsCount > 0 ? (
          <p className="small"><StarRating value={book.averageRating} size="sm" /> {book.averageRating.toFixed(1)} <span className="muted">({book.ratingsCount})</span></p>
        ) : (
          <p className="muted small">{external ? 'Hors catalogue BookNest' : 'Pas encore noté'}</p>
        )}
        {book.genres?.length > 0 && <p className="tags">{book.genres.slice(0, 2).map((g) => <span key={g} className="tag">{g}</span>)}</p>}
        {actions}
      </div>
    </article>
  );
}
