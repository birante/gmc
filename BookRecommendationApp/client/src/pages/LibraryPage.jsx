import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client.js';
import BookTile from '../components/BookTile.jsx';

export default function LibraryPage() {
  const [genres, setGenres] = useState([]);
  const [genre, setGenre] = useState('');
  const [sort, setSort] = useState('popular');
  const [books, setBooks] = useState(null);

  useEffect(() => {
    api.genres().then((d) => setGenres(d.genres)).catch(() => {});
  }, []);

  useEffect(() => {
    api.books({ genre, sort }).then((d) => setBooks(d.books)).catch(() => setBooks([]));
  }, [genre, sort]);

  return (
    <>
      <div className="page-head">
        <div className="page-head__row">
          <div>
            <h1>La bibliothèque BookNest</h1>
            <p className="muted">Tous les livres du catalogue, ajoutés, notés et recommandés par la communauté.</p>
          </div>
          <Link to="/livres/nouveau" className="btn btn--primary">+ Ajouter un livre</Link>
        </div>
      </div>
      <div className="toolbar">
        <div className="chips">
          <button className={`chip ${!genre ? 'chip--on' : ''}`} onClick={() => setGenre('')}>Tous</button>
          {genres.map((g) => (
            <button key={g} className={`chip ${genre === g ? 'chip--on' : ''}`} onClick={() => setGenre(g)}>{g}</button>
          ))}
        </div>
        <label className="select-label">
          Trier par
          <select value={sort} onChange={(e) => setSort(e.target.value)}>
            <option value="popular">Les plus notés</option>
            <option value="rating">Meilleure note</option>
            <option value="recent">Ajouts récents</option>
          </select>
        </label>
      </div>
      {books === null && <div className="loader" aria-label="Chargement" />}
      {books?.length === 0 && <p className="empty">Aucun livre pour l'instant. <Link to="/livres/nouveau">Ajoutez le premier !</Link></p>}
      <div className="book-grid">
        {books?.map((b) => <BookTile key={b.id} book={b} />)}
      </div>
    </>
  );
}
