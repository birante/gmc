import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
import Layout from './components/Layout.jsx';
import { useAuth } from './context/AuthContext.jsx';
import BookPage from './pages/BookPage.jsx';
import BookFormPage from './pages/BookFormPage.jsx';
import HomePage from './pages/HomePage.jsx';
import LibraryPage from './pages/LibraryPage.jsx';
import LoginPage from './pages/LoginPage.jsx';
import NotFoundPage from './pages/NotFoundPage.jsx';
import ProfilePage from './pages/ProfilePage.jsx';
import ReadersPage from './pages/ReadersPage.jsx';
import RecommendPage from './pages/RecommendPage.jsx';
import RecommendationPage from './pages/RecommendationPage.jsx';
import RegisterPage from './pages/RegisterPage.jsx';
import SearchPage from './pages/SearchPage.jsx';

export function RequireAuth({ children }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  if (loading) return <div className="loader" aria-label="Chargement" />;
  if (!user) return <Navigate to="/connexion" replace state={{ from: location.pathname + location.search }} />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<HomePage />} />
        <Route path="connexion" element={<LoginPage />} />
        <Route path="inscription" element={<RegisterPage />} />
        <Route path="recherche" element={<SearchPage />} />
        <Route path="bibliotheque" element={<LibraryPage />} />
        <Route
          path="livres/nouveau"
          element={
            <RequireAuth>
              <BookFormPage />
            </RequireAuth>
          }
        />
        <Route
          path="livres/:id/modifier"
          element={
            <RequireAuth>
              <BookFormPage />
            </RequireAuth>
          }
        />
        <Route path="livres/:id" element={<BookPage />} />
        <Route path="recommandations/:id" element={<RecommendationPage />} />
        <Route
          path="recommander"
          element={
            <RequireAuth>
              <RecommendPage />
            </RequireAuth>
          }
        />
        <Route path="lecteurs" element={<ReadersPage />} />
        <Route path="lecteurs/:username" element={<ProfilePage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
