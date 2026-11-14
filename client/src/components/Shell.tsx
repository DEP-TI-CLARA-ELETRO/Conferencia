import { useEffect, useRef, useState, type ReactNode } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth';
import { useFilters } from '../filters';
import { useTheme } from '../theme';
import { can, initials } from '../types';
import { DateField } from './DateField';
import { FilterSelect, isPostoLabel } from './FilterSelect';
import {
  IconDocs,
  IconHome,
  IconHub,
  IconMoon,
  IconSun,
} from './icons';
import './shell.css';

const NAV = [
  {
    path: '/inicio',
    label: 'Início',
    permission: 'home.view',
    icon: <IconHome size={17} />,
  },
  {
    path: '/caixas',
    label: 'Caixas',
    permission: 'closings.view',
    icon: <IconDocs size={17} />,
  },
];

export function Shell() {
  const { user, logout } = useAuth();
  const { theme, toggle } = useTheme();
  const filters = useFilters();
  const [expanded, setExpanded] = useState(false);
  const collapseTimer = useRef<number | null>(null);

  useEffect(
    () => () => {
      if (collapseTimer.current) window.clearTimeout(collapseTimer.current);
    },
    [],
  );

  if (!user) return null;

  const items = NAV.filter((n) => can(user, n.permission));
  const units = [
    ...new Set(
      user.stores.map((s) => s.businessUnit).filter((u): u is string => Boolean(u)),
    ),
  ];
  const stores = user.stores.filter(
    (s) => !filters.businessUnit || s.businessUnit === filters.businessUnit,
  );
  const unitOptions = [
    { value: '', label: 'Todas' },
    ...units.map((u) => ({
      value: u,
      label: u,
      posto: isPostoLabel(u),
    })),
  ];
  const storeOptions = [
    { value: '', label: 'Todas' },
    ...stores.map((s) => ({
      value: String(s.id),
      label: s.name,
      posto: isPostoLabel(s.name),
    })),
  ];

  const onEnter = () => {
    if (collapseTimer.current) window.clearTimeout(collapseTimer.current);
    setExpanded(true);
  };
  const onLeave = () => {
    collapseTimer.current = window.setTimeout(() => setExpanded(false), 220);
  };

  return (
    <div className="backdrop shell-root">
      <aside
        className={`sidebar ${expanded ? 'expanded' : 'collapsed'}`}
        onMouseEnter={onEnter}
        onMouseLeave={onLeave}
      >
        <div className="sidebar-logo">
          <span className="logo-mark">
            <IconHub size={15} />
          </span>
          <span className="logo-text">CONFERÊNCIA</span>
        </div>
        <nav>
          {items.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) => `nav-tile ${isActive ? 'active' : ''}`}
              title={item.label}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <div className="shell-main">
        <header className="topbar glass">
          <div className="filters">
            <DateField
              label="De"
              value={filters.dateFrom}
              onChange={filters.setDateFrom}
              max={filters.dateTo}
            />
            <DateField
              label="Até"
              value={filters.dateTo}
              onChange={filters.setDateTo}
              min={filters.dateFrom}
            />
            <FilterSelect
              label="Unidade"
              value={filters.businessUnit || ''}
              options={unitOptions}
              onChange={(v) => filters.setBusinessUnit(v || null)}
            />
            <FilterSelect
              label="Loja"
              value={filters.storeId != null ? String(filters.storeId) : ''}
              options={storeOptions}
              wide
              onChange={(v) =>
                filters.setStoreId(v ? Number(v) : null)
              }
            />
          </div>
          <div className="topbar-right">
            <button
              type="button"
              className="btn ghost icon-btn"
              onClick={toggle}
              title={theme === 'light' ? 'Tema escuro' : 'Tema claro'}
              aria-label={theme === 'light' ? 'Tema escuro' : 'Tema claro'}
            >
              {theme === 'light' ? <IconMoon /> : <IconSun />}
            </button>
            <div className="user-chip">
              <div className="user-meta">
                <strong>{user.name}</strong>
                <span className="muted">{user.roleLabel || user.roles[0]}</span>
              </div>
              <button
                type="button"
                className="avatar"
                title="Sair"
                onClick={() => void logout()}
              >
                {initials(user.name)}
              </button>
            </div>
          </div>
        </header>
        <Outlet />
      </div>
    </div>
  );
}

export function Page({
  title,
  subtitle,
  children,
  actions,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>{title}</h1>
          {subtitle ? <p className="muted" style={{ margin: 0 }}>{subtitle}</p> : null}
        </div>
        {actions}
      </div>
      {children}
    </div>
  );
}
