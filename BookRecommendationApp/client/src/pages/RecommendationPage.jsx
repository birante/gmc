import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api/client.js';
import RecommendationCard from '../components/RecommendationCard.jsx';

export default function RecommendationPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [rec, setRec] = useState(null);
  const [error, setError] = useState('');
  useEffect(() => {
    api.recommendation(id).then((d) => setRec(d.recommendation)).catch((e) => setError(e.message));
  }, [id]);
  if (error) return <div className="empty empty--page"><p className="error">{error}</p><Link to="/">Retour au fil</Link></div>;
  if (!rec) return <div className="loader" aria-label="Chargement" />;
  return (
    <div className="narrow">
      <RecommendationCard rec={rec} defaultOpenComments onDelete={() => navigate('/')} />
    </div>
  );
}
