import {
  createContext,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { useAuth } from './auth';

function today() {
  return new Date().toISOString().slice(0, 10);
}

type Filters = {
  dateFrom: string;
  dateTo: string;
  businessUnit: string | null;
  storeId: number | null;
  setDateFrom: (v: string) => void;
  setDateTo: (v: string) => void;
  setBusinessUnit: (v: string | null) => void;
  setStoreId: (v: number | null) => void;
};

const FiltersContext = createContext<Filters | null>(null);

export function FiltersProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [dateFrom, setDateFrom] = useState(today);
  const [dateTo, setDateTo] = useState(today);
  const [businessUnit, setBusinessUnit] = useState<string | null>(null);
  const [storeId, setStoreId] = useState<number | null>(null);

  const value = useMemo(() => {
    const units = [
      ...new Set(
        (user?.stores || [])
          .map((s) => s.businessUnit)
          .filter((u): u is string => Boolean(u)),
      ),
    ];
    void units;
    return {
      dateFrom,
      dateTo,
      businessUnit,
      storeId,
      setDateFrom,
      setDateTo,
      setBusinessUnit: (v: string | null) => {
        setBusinessUnit(v);
        setStoreId(null);
      },
      setStoreId,
    };
  }, [dateFrom, dateTo, businessUnit, storeId, user]);

  return (
    <FiltersContext.Provider value={value}>{children}</FiltersContext.Provider>
  );
}

export function useFilters() {
  const ctx = useContext(FiltersContext);
  if (!ctx) throw new Error('useFilters outside provider');
  return ctx;
}
