import {
  useEffect,
  useId,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from 'react';
import { createPortal } from 'react-dom';
import { IconCalendar, IconChevronLeft, IconChevronRight } from './icons';
import './date-field.css';

const WEEKDAYS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
const MONTHS = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

function parseIso(iso: string) {
  const [y, m, d] = iso.split('-').map(Number);
  if (!y || !m || !d) return null;
  return new Date(y, m - 1, d);
}

function toIso(date: Date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function formatBr(iso: string) {
  const date = parseIso(iso);
  if (!date) return '—';
  return date.toLocaleDateString('pt-BR');
}

function startOfMonth(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function sameDay(a: Date, b: Date) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function buildGrid(month: Date) {
  const first = startOfMonth(month);
  const start = new Date(first);
  start.setDate(first.getDate() - first.getDay());
  const cells: Date[] = [];
  for (let i = 0; i < 42; i += 1) {
    const cell = new Date(start);
    cell.setDate(start.getDate() + i);
    cells.push(cell);
  }
  return cells;
}

type Props = {
  label: string;
  value: string;
  onChange: (iso: string) => void;
  min?: string;
  max?: string;
};

export function DateField({ label, value, onChange, min, max }: Props) {
  const id = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [pos, setPos] = useState<{ top: number; left: number } | null>(null);
  const selected = parseIso(value) || new Date();
  const [view, setView] = useState(() => startOfMonth(selected));

  useEffect(() => {
    if (open) setView(startOfMonth(parseIso(value) || new Date()));
  }, [open, value]);

  useLayoutEffect(() => {
    if (!open) {
      setPos(null);
      return;
    }
    const place = () => {
      const el = triggerRef.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      const width = 272;
      const pad = 8;
      let left = r.left;
      if (left + width > window.innerWidth - pad) {
        left = Math.max(pad, window.innerWidth - width - pad);
      }
      setPos({ top: r.bottom + 8, left });
    };
    place();
    window.addEventListener('resize', place);
    window.addEventListener('scroll', place, true);
    return () => {
      window.removeEventListener('resize', place);
      window.removeEventListener('scroll', place, true);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      const t = e.target as Node;
      if (rootRef.current?.contains(t)) return;
      if (popoverRef.current?.contains(t)) return;
      setOpen(false);
    };
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };
    document.addEventListener('mousedown', onDoc);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onDoc);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  const cells = useMemo(() => buildGrid(view), [view]);
  const today = useMemo(() => {
    const d = new Date();
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }, []);
  const minDate = min ? parseIso(min) : null;
  const maxDate = max ? parseIso(max) : null;

  const pick = (date: Date) => {
    if (minDate && date < minDate) return;
    if (maxDate && date > maxDate) return;
    onChange(toIso(date));
    setOpen(false);
  };

  const onTriggerKey = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      setOpen((v) => !v);
    }
  };

  const popover =
    open && pos
      ? createPortal(
          <div
            ref={popoverRef}
            className="date-popover"
            role="dialog"
            aria-label={`Calendário · ${label}`}
            style={{ top: pos.top, left: pos.left }}
          >
            <div className="date-popover-head">
              <button
                type="button"
                className="date-nav"
                aria-label="Mês anterior"
                onClick={() =>
                  setView(new Date(view.getFullYear(), view.getMonth() - 1, 1))
                }
              >
                <IconChevronLeft size={16} />
              </button>
              <strong>
                {MONTHS[view.getMonth()]} {view.getFullYear()}
              </strong>
              <button
                type="button"
                className="date-nav"
                aria-label="Próximo mês"
                onClick={() =>
                  setView(new Date(view.getFullYear(), view.getMonth() + 1, 1))
                }
              >
                <IconChevronRight size={16} />
              </button>
            </div>

            <div className="date-weekdays">
              {WEEKDAYS.map((d) => (
                <span key={d}>{d}</span>
              ))}
            </div>

            <div className="date-grid">
              {cells.map((cell) => {
                const inMonth = cell.getMonth() === view.getMonth();
                const isSelected = sameDay(cell, selected);
                const isToday = sameDay(cell, today);
                const disabled =
                  (minDate != null && cell < minDate) ||
                  (maxDate != null && cell > maxDate);
                return (
                  <button
                    key={cell.toISOString()}
                    type="button"
                    disabled={disabled}
                    className={[
                      'date-cell',
                      inMonth ? '' : 'muted-month',
                      isSelected ? 'selected' : '',
                      isToday ? 'today' : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={() => pick(cell)}
                  >
                    {cell.getDate()}
                  </button>
                );
              })}
            </div>

            <div className="date-presets">
              <button type="button" onClick={() => pick(today)}>
                Hoje
              </button>
              <button
                type="button"
                onClick={() => {
                  const y = new Date(today);
                  y.setDate(today.getDate() - 1);
                  pick(y);
                }}
              >
                Ontem
              </button>
            </div>
          </div>,
          document.body,
        )
      : null;

  return (
    <div className="date-field" ref={rootRef}>
      <span className="date-field-label" id={id}>
        {label}
      </span>
      <button
        ref={triggerRef}
        type="button"
        className={`date-field-trigger${open ? ' open' : ''}`}
        aria-labelledby={id}
        aria-label={`${label}: ${formatBr(value)}`}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={onTriggerKey}
      >
        <IconCalendar size={16} className="date-field-ico" />
        <span className="date-field-value">{formatBr(value)}</span>
      </button>
      {popover}
    </div>
  );
}
