import {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from 'react';
import { createPortal } from 'react-dom';
import { IconChevronRight, IconFuel } from './icons';
import './filter-select.css';

export function isPostoLabel(name?: string | null) {
  return Boolean(name && /posto|pont[aã]o/i.test(name));
}

export type FilterOption = {
  value: string;
  label: string;
  posto?: boolean;
};

type Props = {
  label: string;
  value: string;
  options: FilterOption[];
  onChange: (value: string) => void;
  placeholder?: string;
  wide?: boolean;
};

export function FilterSelect({
  label,
  value,
  options,
  onChange,
  placeholder = 'Todas',
  wide,
}: Props) {
  const id = useId();
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [pos, setPos] = useState<{
    top: number;
    left: number;
    width: number;
  } | null>(null);
  const [active, setActive] = useState(0);

  const selected = options.find((o) => o.value === value);
  const display = selected?.label ?? placeholder;
  const showFuel = Boolean(selected?.posto ?? isPostoLabel(selected?.label));

  useLayoutEffect(() => {
    if (!open) {
      setPos(null);
      return;
    }
    const place = () => {
      const el = triggerRef.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      const width = Math.max(r.width, wide ? 240 : 180);
      const pad = 8;
      let left = r.left;
      if (left + width > window.innerWidth - pad) {
        left = Math.max(pad, window.innerWidth - width - pad);
      }
      setPos({ top: r.bottom + 6, left, width });
    };
    place();
    const idx = Math.max(
      0,
      options.findIndex((o) => o.value === value),
    );
    setActive(idx);
    window.addEventListener('resize', place);
    window.addEventListener('scroll', place, true);
    return () => {
      window.removeEventListener('resize', place);
      window.removeEventListener('scroll', place, true);
    };
  }, [open, value, options, wide]);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      const t = e.target as Node;
      if (rootRef.current?.contains(t)) return;
      if (menuRef.current?.contains(t)) return;
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

  useEffect(() => {
    if (!open || !menuRef.current) return;
    menuRef.current.focus({ preventScroll: true });
    const item = menuRef.current.querySelector<HTMLElement>(
      `[data-idx="${active}"]`,
    );
    item?.scrollIntoView({ block: 'nearest' });
  }, [active, open]);

  const pick = (next: string) => {
    onChange(next);
    setOpen(false);
    triggerRef.current?.focus();
  };

  const onTriggerKey = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === 'Enter' || e.key === ' ' || e.key === 'ArrowDown') {
      e.preventDefault();
      setOpen(true);
    }
  };

  const onMenuKey = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setActive((i) => Math.min(options.length - 1, i + 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setActive((i) => Math.max(0, i - 1));
    } else if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      const opt = options[active];
      if (opt) pick(opt.value);
    } else if (e.key === 'Home') {
      e.preventDefault();
      setActive(0);
    } else if (e.key === 'End') {
      e.preventDefault();
      setActive(options.length - 1);
    }
  };

  const menu =
    open && pos
      ? createPortal(
          <div
            ref={menuRef}
            id={listId}
            className="filter-menu"
            role="listbox"
            aria-labelledby={id}
            tabIndex={-1}
            style={{ top: pos.top, left: pos.left, minWidth: pos.width }}
            onKeyDown={onMenuKey}
          >
            {options.map((opt, idx) => {
              const posto = opt.posto ?? isPostoLabel(opt.label);
              const isSelected = opt.value === value;
              return (
                <button
                  key={opt.value || '__all__'}
                  type="button"
                  role="option"
                  data-idx={idx}
                  aria-selected={isSelected}
                  className={[
                    'filter-option',
                    isSelected ? 'selected' : '',
                    idx === active ? 'active' : '',
                    posto ? 'posto' : '',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                  onMouseEnter={() => setActive(idx)}
                  onClick={() => pick(opt.value)}
                >
                  <span className="filter-option-ico" aria-hidden>
                    {posto ? <IconFuel size={15} /> : null}
                  </span>
                  <span className="filter-option-label">{opt.label}</span>
                </button>
              );
            })}
          </div>,
          document.body,
        )
      : null;

  return (
    <div className={`filter-field${wide ? ' wide' : ''}`} ref={rootRef}>
      <span className="filter-field-label" id={id}>
        {label}
      </span>
      <button
        ref={triggerRef}
        type="button"
        className={`filter-trigger${open ? ' open' : ''}${showFuel ? ' has-fuel' : ''}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={open ? listId : undefined}
        aria-label={`${label}: ${display}`}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={onTriggerKey}
      >
        {showFuel ? <IconFuel size={15} className="filter-fuel" /> : null}
        <span className="filter-trigger-value">{display}</span>
        <IconChevronRight size={14} className="filter-chevron" />
      </button>
      {menu}
    </div>
  );
}
