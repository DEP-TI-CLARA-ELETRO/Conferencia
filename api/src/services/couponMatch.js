import { PAYMENT_KEYS_ORDERED, PAYMENT_LABELS } from './couponPaymentKeys.js';

function round2(v) {
  return Math.round(v * 100) / 100;
}

export function matchCouponValues({ paymentBreakdown, scanned, closingApurado }) {
  const expected = {};
  for (const [key, v] of Object.entries(paymentBreakdown || {})) {
    if (v && typeof v === 'object') {
      const apurado = v.apurado ?? v.apresentado;
      if (typeof apurado === 'number') expected[key] = apurado;
    } else if (typeof v === 'number') {
      expected[key] = v;
    }
  }

  const keys = new Set([
    ...PAYMENT_KEYS_ORDERED.filter((k) => expected[k] != null || scanned[k] != null),
    ...Object.keys(expected),
    ...Object.keys(scanned),
  ]);

  const lines = [];
  let allOk = true;
  for (const key of keys) {
    const exp = expected[key];
    const sc = scanned[key];
    if (exp == null && sc == null) continue;
    const diff = round2((sc ?? 0) - (exp ?? 0));
    const ok = exp != null && sc != null && Math.abs(diff) < 0.015;
    if (!ok) allOk = false;
    lines.push({
      key,
      label: PAYMENT_LABELS[key] || key,
      expected: exp ?? null,
      scanned: sc ?? null,
      diff,
      ok,
    });
  }

  const scannedTotal = Object.values(scanned).reduce((a, b) => a + b, 0);
  const expectedTotal = Object.keys(expected).length
    ? Object.values(expected).reduce((a, b) => a + b, 0)
    : closingApurado ?? null;
  const totalDiff =
    expectedTotal == null ? null : round2(scannedTotal - expectedTotal);
  if (totalDiff != null && Math.abs(totalDiff) >= 0.015) allOk = false;
  if (!lines.length) allOk = false;

  return {
    ok: allOk,
    lines,
    expectedTotal: expectedTotal == null ? null : round2(expectedTotal),
    scannedTotal: round2(scannedTotal),
    totalDiff,
  };
}
