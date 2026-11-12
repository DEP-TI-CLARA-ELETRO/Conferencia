/// Chaves alinhadas ao payment_breakdown do sync WebPosto.
abstract final class CouponPaymentKeys {
  static const ordered = [
    'dinheiro',
    'notaPrazo',
    'cheque',
    'chequePre',
    'cartao',
    'cartaFrete',
    'valeCliente',
    'emprestimo',
    'prePag',
    'despesa',
    'valeFun',
    'chequePagar',
    'transfBanc',
    'transfDeb',
    'fundoCxDeb',
  ];

  static const labels = {
    'dinheiro': 'Dinheiro',
    'notaPrazo': 'Notas a prazo',
    'cheque': 'Cheque',
    'chequePre': 'Cheque pré',
    'cartao': 'Cartão',
    'cartaFrete': 'Carta frete',
    'valeCliente': 'Vale cliente',
    'emprestimo': 'Empréstimo',
    'prePag': 'Pré-pagamento',
    'despesa': 'Despesa',
    'valeFun': 'Vale funcionário',
    'chequePagar': 'Cheque a pagar',
    'transfBanc': 'Transferência bancária',
    'transfDeb': 'Transferência débito',
    'fundoCxDeb': 'Fundo de caixa débito',
  };

  /// Sinônimos OCR → chave canônica.
  static const aliases = <String, String>{
    'DINHEIRO': 'dinheiro',
    'ESPECIE': 'dinheiro',
    'ESPÉCIE': 'dinheiro',
    'CASH': 'dinheiro',
    'NOTA PRAZO': 'notaPrazo',
    'NOTAS A PRAZO': 'notaPrazo',
    'NOTAS PRAZO': 'notaPrazo',
    'NOTA A PRAZO': 'notaPrazo',
    'A PRAZO': 'notaPrazo',
    'PRAZO': 'notaPrazo',
    'CHEQUE': 'cheque',
    'CHEQUE PRE': 'chequePre',
    'CHEQUE PREDATADO': 'chequePre',
    'CHEQUE PRE-DATADO': 'chequePre',
    'CARTAO': 'cartao',
    'CARTÃO': 'cartao',
    'CARTAO CREDITO': 'cartao',
    'CARTAO DEBITO': 'cartao',
    'TEF': 'cartao',
    'POS': 'cartao',
    'CARTA FRETE': 'cartaFrete',
    'VALE CLIENTE': 'valeCliente',
    'EMPRESTIMO': 'emprestimo',
    'EMPRÉSTIMO': 'emprestimo',
    'PRE PAG': 'prePag',
    'PREPAG': 'prePag',
    'DESPESA': 'despesa',
    'VALE FUN': 'valeFun',
    'VALE FUNCIONARIO': 'valeFun',
    'VALE FUNCIONÁRIO': 'valeFun',
    'CHEQUE PAGAR': 'chequePagar',
    'TRANSF BANC': 'transfBanc',
    'TRANSFERENCIA': 'transfBanc',
    'TRANSFERÊNCIA': 'transfBanc',
    'TRANSF DEB': 'transfDeb',
    'FUNDO CX DEB': 'fundoCxDeb',
    'FUNDO DE CAIXA': 'fundoCxDeb',
  };

  static String? resolveKey(String rawLabel) {
    final n = rawLabel
        .toUpperCase()
        .replaceAll(RegExp(r'[^\wÁÉÍÓÚÂÊÔÃÕÇ\s+-]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (n.isEmpty) return null;
    if (aliases.containsKey(n)) return aliases[n];
    for (final e in aliases.entries) {
      if (n.contains(e.key) || e.key.contains(n)) return e.value;
    }
    return null;
  }
}
