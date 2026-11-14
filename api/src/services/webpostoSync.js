import { Store } from '../models/Store.js';
import { CashClosing } from '../models/CashClosing.js';

function dateStr(d) {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseDate(v) {
  if (v == null) return null;
  const s = String(v);
  const iso = s.length >= 10 ? s.slice(0, 10) : s;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : iso;
}

function parseDateTime(v) {
  if (v == null) return null;
  const d = new Date(String(v));
  return Number.isNaN(d.getTime()) ? null : d;
}

function asNum(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = Number.parseFloat(String(v));
  return Number.isNaN(n) ? null : n;
}

const FORMS = [
  'dinheiro', 'notaPrazo', 'cheque', 'chequePre', 'cartao', 'cartaFrete',
  'valeCliente', 'emprestimo', 'prePag', 'despesa', 'valeFun', 'chequePagar',
  'transfBanc', 'transfDeb', 'fundoCxDeb',
];

function paymentBreakdown(ap) {
  if (!ap) return {};
  const out = {};
  for (const f of FORMS) {
    const apresentado = asNum(ap[`${f}Apresentado`]);
    const apurado = asNum(ap[`${f}Apurado`]);
    const diferenca = asNum(ap[`${f}Diferenca`]);
    if (apresentado == null && apurado == null && diferenca == null) continue;
    out[f] = { apresentado, apurado, diferenca };
  }
  return out;
}

async function upsertStore({ connector, externalCode, code, name, businessUnit }) {
  let store = await Store.findOne({ connector, externalCode });
  if (store) {
    store.name = name;
    store.businessUnit = businessUnit;
    store.active = true;
    await store.save();
    return store.id;
  }
  store = await Store.findOne({ code });
  if (store) {
    store.name = name;
    store.connector = connector;
    store.externalCode = externalCode;
    store.businessUnit = businessUnit;
    store.active = true;
    await store.save();
    return store.id;
  }
  store = await Store.create({
    code,
    name,
    connector,
    externalCode,
    businessUnit,
    active: true,
  });
  return store.id;
}

export async function syncWebposto(client, { from, to, empresaCodigo }) {
  const fromStr = typeof from === 'string' ? from : dateStr(from);
  const toStr = typeof to === 'string' ? to : dateStr(to);

  const companies = await client.empresas();
  let companiesUpserted = 0;
  const storeByEmpresa = new Map();

  for (const e of companies) {
    const codigo = e.empresaCodigo;
    if (codigo == null) continue;
    if (empresaCodigo != null && codigo !== empresaCodigo) continue;
    const fantasia = (e.fantasia || '').trim();
    const razao = (e.razao || '').trim();
    const name = fantasia || razao || `Posto ${codigo}`;
    const id = await upsertStore({
      connector: 'webposto',
      externalCode: String(codigo),
      code: `WP-${codigo}`,
      name,
      businessUnit: 'posto',
    });
    storeByEmpresa.set(codigo, id);
    companiesUpserted += 1;
  }

  const caixas = await client.caixas({
    dataInicial: fromStr,
    dataFinal: toStr,
    empresaCodigo,
  });
  const apresentados = await client.caixasApresentado({
    dataInicial: fromStr,
    dataFinal: toStr,
  });

  const apIndex = new Map();
  for (const a of apresentados) {
    if (a.empresaCodigo == null || a.caixaCodigo == null) continue;
    apIndex.set(`${a.empresaCodigo}|${a.caixaCodigo}`, a);
  }

  let closingsUpserted = 0;
  for (const c of caixas) {
    const emp = c.empresaCodigo;
    const caixaCodigo = c.caixaCodigo;
    if (emp == null || caixaCodigo == null) continue;

    let storeId = storeByEmpresa.get(emp);
    if (storeId == null) {
      storeId = await upsertStore({
        connector: 'webposto',
        externalCode: String(emp),
        code: `WP-${emp}`,
        name: `Posto ${emp}`,
        businessUnit: 'posto',
      });
      storeByEmpresa.set(emp, storeId);
    }

    const movementDate = parseDate(c.dataMovimento);
    if (!movementDate) continue;
    const shiftCode = c.turnoCodigo ?? -1;
    const ap = apIndex.get(`${emp}|${caixaCodigo}`);
    const payload = {
      storeId,
      connector: 'webposto',
      externalCodigo: c.codigo ?? null,
      externalCaixaCodigo: caixaCodigo,
      movementDate,
      shiftCode,
      shiftLabel: c.turno ?? null,
      pdvCode: c.pdvCodigo ?? null,
      employeeCode: c.funcionarioCodigo ?? null,
      openedAt: parseDateTime(c.abertura),
      closedAt: parseDateTime(c.fechamento),
      closed: Boolean(c.fechado),
      consolidated: Boolean(c.consolidado),
      blocked: Boolean(c.bloqueado),
      apurado: asNum(c.apurado),
      diferenca: asNum(c.diferenca),
      stage: 'pdv_imported',
      paymentBreakdown: paymentBreakdown(ap),
      rawCaixa: c,
      rawApresentado: ap ?? null,
      syncedAt: new Date(),
    };

    const existing = await CashClosing.findOne({
      storeId,
      connector: 'webposto',
      externalCaixaCodigo: caixaCodigo,
      movementDate,
      shiftCode,
    });

    if (existing) {
      Object.assign(existing, payload);
      await existing.save();
    } else {
      await CashClosing.create(payload);
    }
    closingsUpserted += 1;
  }

  return { companiesUpserted, closingsUpserted, from: fromStr, to: toStr };
}
