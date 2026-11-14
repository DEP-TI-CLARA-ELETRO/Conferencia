export type Store = {
  id: number;
  code: string;
  name: string;
  businessUnit?: string | null;
};

export type User = {
  id: string;
  email: string;
  name: string;
  registration?: string | null;
  roles: string[];
  permissions: string[];
  stores: Store[];
  roleLabel?: string;
};

export type Session = {
  token: string;
  expiresAt: string;
  user: User;
};

export type Closing = {
  id: string;
  storeId: number;
  storeName: string;
  connector: string;
  caixaCodigo: number;
  movementDate: string;
  shiftLabel?: string | null;
  pdvCode?: number | null;
  employeeCode?: number | null;
  openedAt?: string | null;
  closedAt?: string | null;
  closed: boolean;
  consolidated: boolean;
  apurado?: number | null;
  diferenca?: number | null;
  stage: string;
  paymentBreakdown: Record<string, unknown>;
};

export type ClosingDetail = {
  employeeName?: string | null;
  payments: { name: string; amount: number }[];
  paymentsTotal: number;
  salesCount: number;
  sales: {
    soldAt: string;
    clientDocument?: string | null;
    invoiceNumber?: string | null;
    total: number;
    cancelled: boolean;
  }[];
  warning?: string;
};

export type ClosingCoupon = {
  id: string;
  closingId: string;
  filename: string;
  contentType: string;
  status: 'uploaded' | 'ocr_pending' | 'ocr_ready' | 'confirmed' | 'failed';
  proposedValues: Record<string, number>;
  confirmedValues?: Record<string, number> | null;
  matchResult?: {
    ok: boolean;
    lines: {
      key: string;
      label: string;
      expected?: number | null;
      scanned?: number | null;
      diff: number;
      ok: boolean;
    }[];
    expectedTotal?: number | null;
    scannedTotal?: number;
    totalDiff?: number | null;
  } | null;
  ocrWarning?: string | null;
  ocrRuns: {
    engine: string;
    rawText?: string | null;
    parsed: Record<string, number>;
    confidence?: number | null;
    error?: string | null;
  }[];
  createdAt?: string;
  confirmedAt?: string | null;
};

export type Coupon = ClosingCoupon;

export const PAYMENT_LABELS: Record<string, string> = {
  dinheiro: 'Dinheiro',
  notaPrazo: 'Notas a prazo',
  cheque: 'Cheque',
  chequePre: 'Cheque pré',
  cartao: 'Cartão',
  cartaFrete: 'Carta frete',
  valeCliente: 'Vale cliente',
  emprestimo: 'Empréstimo',
  prePag: 'Pré-pagamento',
  despesa: 'Despesa',
  valeFun: 'Vale funcionário',
  chequePagar: 'Cheque a pagar',
  transfBanc: 'Transferência bancária',
  transfDeb: 'Transferência débito',
  fundoCxDeb: 'Fundo de caixa débito',
};

export function can(user: User | null | undefined, permission: string) {
  return Boolean(user?.permissions?.includes(permission));
}

export function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  if (parts.length === 1) return parts[0][0]!.toUpperCase();
  return (parts[0][0]! + parts[parts.length - 1]![0]!).toUpperCase();
}
