import 'coupon_payment_keys.dart';

/// Extrai valores monetários por forma de pagamento a partir do texto OCR.
class CouponOcrParser {
  Map<String, double> parse(String text) {
    final out = <String, double>{};
    final lines = text
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    for (final line in lines) {
      final money = _findMoney(line);
      if (money == null) continue;
      final key = CouponPaymentKeys.resolveKey(line);
      if (key == null) continue;
      // Mantém o maior valor visto para a chave (evita lixo de linhas repetidas).
      final prev = out[key];
      if (prev == null || money > prev) out[key] = money;
    }
    return out;
  }

  double? _findMoney(String line) {
    final patterns = [
      RegExp(r'R\$\s*([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2})'),
      RegExp(r'R\$\s*([0-9]+,[0-9]{2})'),
      RegExp(r'([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2})\s*$'),
      RegExp(r'([0-9]+[.,][0-9]{2})\s*$'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(line);
      if (m == null) continue;
      final raw = m.group(1)!;
      final normalized = raw.contains(',')
          ? raw.replaceAll('.', '').replaceAll(',', '.')
          : raw;
      return double.tryParse(normalized);
    }
    return null;
  }
}
