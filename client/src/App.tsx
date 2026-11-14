import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth';
import { FiltersProvider } from './filters';
import { Shell } from './components/Shell';
import { LoginPage } from './pages/LoginPage';
import { HomePage } from './pages/HomePage';
import { ClosingsPage } from './pages/ClosingsPage';
import { can } from './types';

function Guard({
  permission,
  children,
}: {
  permission?: string;
  children: React.ReactNode;
}) {
  const { status, user } = useAuth();
  if (status === 'unknown') {
    return (
      <div className="backdrop loading-block">
        <div className="spinner" />
        <p className="muted">Carregando…</p>
      </div>
    );
  }
  if (status !== 'authenticated') return <Navigate to="/login" replace />;
  if (permission && !can(user, permission)) {
    return <Navigate to="/inicio" replace />;
  }
  return <>{children}</>;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <Guard>
            <FiltersProvider>
              <Shell />
            </FiltersProvider>
          </Guard>
        }
      >
        <Route index element={<Navigate to="/inicio" replace />} />
        <Route
          path="inicio"
          element={
            <Guard permission="home.view">
              <HomePage />
            </Guard>
          }
        />
        <Route
          path="caixas"
          element={
            <Guard permission="closings.view">
              <ClosingsPage />
            </Guard>
          }
        />
      </Route>
      <Route path="*" element={<Navigate to="/inicio" replace />} />
    </Routes>
  );
}
