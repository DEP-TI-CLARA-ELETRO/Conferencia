const SALES_LIMIT = 100;
const CACHE_MS = 2 * 60 * 1000;

const cache = new Map();
const inflight = new Map();

function asInt(v) {
  if (v == null) return null;
  if (typeof v === 'number') return Math.trunc(v);
  const n = Number.parseInt(String(v), 10);
  return Number.isNaN(n) ? null : n;
}

function asDouble(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = Number.parseFloat(String(v));
  return Number.isNaN(n) ? null : n;
}

function cancelled(v) {
  return Boolean(v?.cancelada || v?.cancelado || v?.situacao === 'C');
}

async function cached(key, loader) {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_MS) return hit.data;
  if (inflight.has(key)) return inflight.get(key);
  const p = loader()
    .then((data) => {
      cache.set(key, { at: Date.now(), data });
      inflight.delete(key);
      return data;
    })
    .catch((err) => {
      inflight.delete(key);
      throw err;
    });
  inflight.set(key, p);
  return p;
}

export async function loadClosingDetail(client, {
  caixaCodigo,
  movementDate,
  empresaCodigo,
  employeeCode,
}) {
  try {
    const dayKey = `${empresaCodigo}|${movementDate}`;
    const [vendas, formas, employeeName] = await Promise.all([
      cached(`${dayKey}|vendas`, () =>
        client.vendas({
          dataInicial: movementDate,
          dataFinal: movementDate,
          empresaCodigo,
        }),
      ),
      cached(`${dayKey}|formas`, () =>
        client.vendasFormaPagamento({
          dataInicial: movementDate,
          dataFinal: movementDate,
          empresaCodigo,
        }),
      ),
      employeeNameOf(client, employeeCode, empresaCodigo),
    ]);

    const ofCaixa = vendas.filter((v) => asInt(v.caixaCodigo) === caixaCodigo);
    const activeIds = new Set(
      ofCaixa
        .filter((v) => !cancelled(v) && asInt(v.vendaCodigo) != null)
        .map((v) => asInt(v.vendaCodigo)),
    );

    const totals = new Map();
    for (const f of formas) {
      const venda = asInt(f.vendaCodigo);
      if (venda == null || !activeIds.has(venda)) continue;
      const amount = asDouble(f.valorPagamento) || 0;
      if (!amount) continue;
      const name =
        (f.nomeFormaPagamento || '').trim() ||
        (f.tipoFormaPagamento || '').trim() ||
        'Outros';
      totals.set(name, (totals.get(name) || 0) + amount);
    }

    const payments = [...totals.entries()]
      .map(([name, amount]) => ({ name: name.toUpperCase(), amount }))
      .sort((a, b) => b.amount - a.amount);
    const paymentsTotal = payments.reduce((s, p) => s + p.amount, 0);

    ofCaixa.sort((a, b) => String(b.dataHora || '').localeCompare(String(a.dataHora || '')));
    const sales = ofCaixa.slice(0, SALES_LIMIT).map((v) => {
      const doc = (v.clienteCpfCnpj || '').trim();
      const nota = (v.notaNumero || '').trim();
      return {
        soldAt: String(v.dataHora || ''),
        clientDocument: doc || null,
        invoiceNumber: nota || null,
        total: asDouble(v.totalVenda) || 0,
        cancelled: cancelled(v),
      };
    });

    return {
      employeeName,
      payments,
      paymentsTotal,
      salesCount: ofCaixa.length,
      sales,
    };
  } catch {
    return {
      warning: 'Nao foi possivel consultar as vendas deste caixa no WebPosto.',
      payments: [],
      paymentsTotal: 0,
      salesCount: 0,
      sales: [],
    };
  }
}

async function employeeNameOf(client, code, empresaCodigo) {
  if (code == null) return null;
  try {
    const rows = await cached(`func|${code}`, () => client.funcionarios(code));
    let match = null;
    for (const row of rows) {
      if (asInt(row.funcionarioCodigo) !== code) continue;
      match ??= row;
      if (asInt(row.empresaCodigo) === empresaCodigo) {
        match = row;
        break;
      }
    }
    const name = (match?.nome || '').trim();
    return name || null;
  } catch {
    return null;
  }
}
