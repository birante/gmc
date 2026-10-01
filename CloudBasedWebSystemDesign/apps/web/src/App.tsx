import type { ReactNode } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router';
import { Spinner } from './components/Feedback';
import { Layout } from './components/Layout';
import { useAuth } from './hooks/auth-context';
import { AdminPage } from './pages/AdminPage';
import { DashboardPage } from './pages/DashboardPage';
import { LoginPage } from './pages/LoginPage';
import { NewPatientPage } from './pages/NewPatientPage';
import { PatientDetailPage } from './pages/PatientDetailPage';
import { PatientsPage } from './pages/PatientsPage';
import { PublicLookupPage } from './pages/PublicLookupPage';
import { WorklistPage } from './pages/WorklistPage';

function RequireAuth({ children, role }: { children: ReactNode; role?: 'ADMIN' }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  if (loading) return <Spinner />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  if (role && user.role !== role) return <Navigate to="/" replace />;
  return <>{children}</>;
}

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/lookup" element={<PublicLookupPage />} />
      <Route element={<RequireAuth><Layout /></RequireAuth>}>
        <Route index element={<DashboardPage />} />
        <Route path="patients" element={<PatientsPage />} />
        <Route path="patients/new" element={<NewPatientPage />} />
        <Route path="patients/:id" element={<PatientDetailPage />} />
        <Route path="worklist" element={<WorklistPage />} />
        <Route path="admin" element={<RequireAuth role="ADMIN"><AdminPage /></RequireAuth>} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
