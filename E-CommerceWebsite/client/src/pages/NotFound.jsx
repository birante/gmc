import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="container page">
      <div className="empty">
        <h1>404</h1>
        <p>Cette page n'existe pas.</p>
        <Link to="/" className="btn btn-primary">Retour à l'accueil</Link>
      </div>
    </div>
  );
}
