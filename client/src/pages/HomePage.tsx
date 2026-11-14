import { Link } from 'react-router-dom';
import { Page } from '../components/Shell';
import { IconDocs } from '../components/icons';
import { useAuth } from '../auth';
import './home.css';

export function HomePage() {
  const { user } = useAuth();
  const firstName = user?.name?.split(' ')[0] || '';

  return (
    <Page title="Início" subtitle={`Olá, ${firstName}. Resumo do dia.`}>
      <div className="home-hero glass">
        <div>
          <p className="home-kicker">Grupo Clara</p>
          <h2>Conferência de caixas</h2>
          <p className="muted">
            Sincronize o WebPosto, confira diferenças por forma de pagamento e
            anexe cupons com OCR para cruzar o apurado.
          </p>
          <Link className="btn" to="/caixas">
            <IconDocs size={16} />
            Ir para Caixas
          </Link>
        </div>
        <div className="home-orb" aria-hidden />
      </div>

      <div className="kpi-grid">
        <div className="kpi glass">
          <span className="muted">Caixas do dia</span>
          <strong className="kpi-placeholder">—</strong>
          <span className="kpi-note">Em breve</span>
        </div>
        <div className="kpi glass">
          <span className="muted">Divergentes</span>
          <strong className="kpi-placeholder">—</strong>
          <span className="kpi-note">Em breve</span>
        </div>
        <div className="kpi glass">
          <span className="muted">Consolidados</span>
          <strong className="kpi-placeholder">—</strong>
          <span className="kpi-note">Em breve</span>
        </div>
      </div>
    </Page>
  );
}
