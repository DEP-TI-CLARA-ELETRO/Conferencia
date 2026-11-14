import { PAYMENT_ALIASES, resolvePaymentKey } from './couponPaymentKeys.js';

function fixConfusions(text) {
  let t = text.toUpperCase();
  const fixes = {
    DENEIRO: 'DINHEIRO',
    DINHERO: 'DINHEIRO',
    DINHEIR0: 'DINHEIRO',
    D1NHEIRO: 'DINHEIRO',
    CARTAD: 'CARTAO',
    'CARTÃ0': 'CARTAO',
    'CARTÂO': 'CARTAO',
    CREOLIO: 'CREDITO',
    DEBLIO: 'DEBITO',
    'TRANSFERENCIA.': 'TRANSFERENCIA',
    'NOTAS A PRAZ0': 'NOTAS A PRAZO',
    'NOTA5 A PRAZO': 'NOTAS A PRAZO',
    'FUNDO CX DE8': 'FUNDO CX DEB',
    'VENDAS DINHEIRO': 'DINHEIRO',
    'VENDAS.': 'VENDAS',
  };
  for (const [k, v] of Object.entries(fixes)) t = t.split(k).join(v);
  t = t.replace(/\b(VISA|MASTER|MASTERCARD|ELO|AMEX|SAFRA)\s+(CREDITO|DEBITO|PIX)\b/g, 'CARTAO');
  t = t.replace(/\bSAFRA\s+PIX\b/g, 'CARTAO');
  t = t.replace(/\bPIX\b/g, 'CARTAO');
  return t;
}

function normalizeOcr(text) {
  return text
    .replace(/[—–]/g, '-')
    .replace(/…/g, '.')
    .replace(/[|[\]]/g, ' ');
}

function toDouble(raw) {
  const normalized = raw.includes(',')
    ? raw.replace(/\./g, '').replace(',', '.')
    : raw;
  const n = Number.parseFloat(normalized);
  return Number.isNaN(n) ? null : n;
}

function findMoney(line) {
  const re = /(?:R\$\s*)?([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2}|[0-9]+,[0-9]{2})/g;
  const matches = [...line.matchAll(re)];
  if (!matches.length) return null;
  let best = null;
  for (const m of matches) {
    const v = toDouble(m[1]);
    if (v == null) continue;
    if (!m[1].includes('.') && v === Math.round(v) && matches.length > 1) continue;
    best = v;
  }
  return best ?? toDouble(matches[matches.length - 1][1]);
}

export function parseCouponText(text) {
  const out = {};
  const normalized = normalizeOcr(fixConfusions(text));
  const lines = normalized
    .replace(/\r/g, '\n')
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);

  for (const line of lines) {
    const key = resolvePaymentKey(line);
    if (!key) continue;
    const money = findMoney(line);
    if (money == null) continue;
    out[key] = money;
  }

  if (!Object.keys(out).length) {
    for (const [alias, key] of Object.entries(PAYMENT_ALIASES)) {
      const re = new RegExp(
        `${alias.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}[^0-9]{0,40}([0-9]{1,3}(?:\\.[0-9]{3})*,[0-9]{2}|[0-9]+,[0-9]{2})`,
        'i',
      );
      const m = normalized.match(re);
      if (!m) continue;
      const v = toDouble(m[1]);
      if (v == null) continue;
      if (out[key] == null || v > out[key]) out[key] = v;
    }
  }
  return out;
}
