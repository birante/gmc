import { Link } from 'react-router-dom';
import EmptyState from '../components/EmptyState.jsx';

export default function NotFoundPage() {
  return (
    <div className="container section">
      <EmptyState icon="🧭" title="Page introuvable">
        <p>La page que vous cherchez n'existe pas ou a été déplacée.</p>
        <Link to="/" className="btn btn-primary">Retour à l'accueil</Link>
      </EmptyState>
    </div>
  );
}
