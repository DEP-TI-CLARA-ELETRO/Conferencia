import { useState, type FormEvent } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../auth';
import { IconHub } from '../components/icons';
import './login.css';

export function LoginPage() {
  const { status, login } = useAuth();
  const [email, setEmail] = useState('admin@conferencia.local');
  const [password, setPassword] = useState('admin123');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (status === 'authenticated') return <Navigate to="/inicio" replace />;
  if (status === 'unknown') {
    return (
      <div className="backdrop loading-block">
        <div className="spinner" />
        <p className="muted">Carregando…</p>
      </div>
    );
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await login(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Falha no login');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="backdrop login-wrap">
      <form className="login-card glass" onSubmit={onSubmit}>
        <div className="login-brand">
          <span className="logo-mark">
            <IconHub size={24} />
          </span>
          <h1>Conferência</h1>
          <p className="muted">Grupo Clara — caixas e cupons</p>
        </div>
        <label className="field">
          E-mail
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="username"
          />
        </label>
        <label className="field">
          Senha
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />
        </label>
        {error ? <p className="login-error">{error}</p> : null}
        <button className="btn" type="submit" disabled={loading}>
          {loading ? 'Entrando…' : 'Entrar'}
        </button>
        <p className="login-hint">Acesso interno · sessão segura</p>
      </form>
    </div>
  );
}
