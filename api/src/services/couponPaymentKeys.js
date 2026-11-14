export const PAYMENT_KEYS_ORDERED = [
  'dinheiro', 'notaPrazo', 'cheque', 'chequePre', 'cartao', 'cartaFrete',
  'valeCliente', 'emprestimo', 'prePag', 'despesa', 'valeFun', 'chequePagar',
  'transfBanc', 'transfDeb', 'fundoCxDeb',
];

export const PAYMENT_LABELS = {
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

export const PAYMENT_ALIASES = {
  'VENDAS DINHEIRO': 'dinheiro',
  DINHEIRO: 'dinheiro',
  ESPECIE: 'dinheiro',
  'ESPÉCIE': 'dinheiro',
  CASH: 'dinheiro',
  'NOTAS A PRAZO': 'notaPrazo',
  'NOTA PRAZO': 'notaPrazo',
  'NOTAS PRAZO': 'notaPrazo',
  'NOTA A PRAZO': 'notaPrazo',
  'CHEQUE A PRAZO': 'cheque',
  'CHEQUE PREDATADO': 'chequePre',
  'CHEQUE PRE-DATADO': 'chequePre',
  'CHEQUE PRE': 'chequePre',
  'CHEQUE PAGAR': 'chequePagar',
  CHEQUE: 'cheque',
  'CARTAO CREDITO': 'cartao',
  'CARTAO DEBITO': 'cartao',
  'CREDITO A VISTA': 'cartao',
  'CRÉDITO À VISTA': 'cartao',
  'CREDITO À VISTA': 'cartao',
  'DEBITO A VISTA': 'cartao',
  'DÉBITO À VISTA': 'cartao',
  'CARTEIRA DIGITAL': 'cartao',
  'VALE REFEICAO': 'cartao',
  'VALE REFEIÇÃO': 'cartao',
  'VALE ALIMENTACAO': 'cartao',
  'VALE ALIMENTAÇÃO': 'cartao',
  MASTERCARD: 'cartao',
  VISA: 'cartao',
  ELO: 'cartao',
  'CARTÃO': 'cartao',
  CARTAO: 'cartao',
  CREDITO: 'cartao',
  DEBITO: 'cartao',
  TEF: 'cartao',
  POS: 'cartao',
  'CARTA FRETE': 'cartaFrete',
  'VALE CLIENTE': 'valeCliente',
  EMPRESTIMO: 'emprestimo',
  'EMPRÉSTIMO': 'emprestimo',
  'PRE PAG': 'prePag',
  PREPAG: 'prePag',
  DESPESAS: 'despesa',
  DESPESA: 'despesa',
  'VALE FUNCIONARIO': 'valeFun',
  'VALE FUNCIONÁRIO': 'valeFun',
  'VALE FUN': 'valeFun',
  'TRANSFERENCIA BANCARIA': 'transfBanc',
  TRANSFERENCIA: 'transfBanc',
  'TRANSFERÊNCIA': 'transfBanc',
  'TRANSF BANC': 'transfBanc',
  'TRANSF DEB': 'transfDeb',
  'FUNDO CX DEB': 'fundoCxDeb',
  'FUNDO DE CAIXA': 'fundoCxDeb',
  'A PRAZO': 'notaPrazo',
};

export function resolvePaymentKey(rawLabel) {
  const n = rawLabel
    .toUpperCase()
    .replace(/[^\wÁÉÍÓÚÂÊÔÃÕÇ\s+-]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!n) return null;
  const sorted = Object.entries(PAYMENT_ALIASES).sort(
    (a, b) => b[0].length - a[0].length,
  );
  for (const [alias, key] of sorted) {
    if (n === alias || n.includes(alias)) return key;
  }
  return null;
}
