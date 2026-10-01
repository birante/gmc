import { Link } from 'react-router-dom';

export default function NotFoundPage() {
  return (
    <div className="empty empty--page">
      <h1>Page introuvable</h1>
      <p>Ce rayon de la bibliothèque n'existe pas… ou plus.</p>
      <Link to="/" className="btn btn--primary">Retour à l'accueil</Link>
    </div>
  );
}
