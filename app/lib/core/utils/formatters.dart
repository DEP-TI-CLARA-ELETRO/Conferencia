import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _longDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

String formatMoney(num value) => _money.format(value).replaceAll('\u00a0', ' ');

/// Diferenca com sinal explicito: +R$ 10,00 / -R$ 20,00 / R$ 0,00
String formatDiff(num value) {
  if (value == 0) return formatMoney(0);
  final sign = value > 0 ? '+' : '-';
  return '$sign${formatMoney(value.abs())}';
}

String formatDate(DateTime d) => _date.format(d);

String formatLongDate(DateTime d) {
  final s = _longDate.format(d);
  return s[0].toUpperCase() + s.substring(1);
}
