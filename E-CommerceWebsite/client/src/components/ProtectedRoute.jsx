import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import Spinner from './Spinner.jsx';

export default function ProtectedRoute({ children, admin = false }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  if (loading) return <Spinner />;
  if (!user) return <Navigate to="/connexion" replace state={{ from: location.pathname }} />;
  if (admin && user.role !== 'admin') {
    return (
      <div className="container page">
        <div className="empty">
          <h2>Accès refusé</h2>
          <p>Cette page est réservée aux administrateurs.</p>
        </div>
      </div>
    );
  }
  return children;
}
