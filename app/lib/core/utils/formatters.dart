import 'package:intl/intl.dart';

// Formatadores reutilizáveis (criados uma vez, usados em várias telas).
final _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _longDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR'); // ex.: segunda-feira, 3 de novembro

/// Dinheiro no padrão brasileiro: R$ 1.234,56
/// replaceAll remove o espaço especial (&nbsp;) que o intl às vezes coloca.
String formatMoney(num value) => _money.format(value).replaceAll('\u00a0', ' ');

/// Diferença com sinal: +R$ 10,00 / -R$ 20,00 / R$ 0,00
String formatDiff(num value) {
  if (value == 0) return formatMoney(0);
  final sign = value > 0 ? '+' : '-';
  return '$sign${formatMoney(value.abs())}'; // abs = valor absoluto (sem sinal)
}

String formatDate(DateTime d) => _date.format(d);

/// Data por extenso com a primeira letra maiúscula.
String formatLongDate(DateTime d) {
  final s = _longDate.format(d);
  return s[0].toUpperCase() + s.substring(1);
}

/// Um dia ou intervalo: 04/11/2026 · 01/11/2026 – 04/11/2026
String formatDateRange(DateTime from, DateTime to) {
  if (from.year == to.year && from.month == to.month && from.day == to.day) {
    return formatDate(from);
  }
  return '${formatDate(from)} – ${formatDate(to)}';
}

String formatLongDateRange(DateTime from, DateTime to) {
  if (from.year == to.year && from.month == to.month && from.day == to.day) {
    return formatLongDate(from);
  }
  return '${formatDate(from)} a ${formatDate(to)}';
}
