import 'package:shared/shared.dart';

import '../../integrations/webposto/webposto_client.dart';

/// Monta o painel de um caixa com vendas e formas de pagamento do WebPosto.
/// Só leitura: nenhuma chamada grava no WebPosto.
class ClosingDetailService {
  ClosingDetailService(this._client);

  final WebpostoClient _client;

  static const salesShownLimit = 100;
  static const _cacheFor = Duration(minutes: 2);

  final Map<String, _CachedRows> _cache = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _inflight = {};

  Future<ClosingDetailDto> load({
    required int caixaCodigo,
    required String movementDate,
    required int empresaCodigo,
    int? employeeCode,
  }) async {
    try {
      final dayKey = '$empresaCodigo|$movementDate';
      final vendasFuture = _cached('$dayKey|vendas', () => _client.vendas(
            dataInicial: movementDate,
            dataFinal: movementDate,
            empresaCodigo: empresaCodigo,
          ));
      final formasFuture = _cached('$dayKey|formas', () => _client.vendasFormaPagamento(
            dataInicial: movementDate,
            dataFinal: movementDate,
            empresaCodigo: empresaCodigo,
          ));
      final nameFuture = _employeeName(employeeCode, empresaCodigo);
      final vendas = await vendasFuture;
      final formas = await formasFuture;
      final employeeName = await nameFuture;

      final ofCaixa = vendas.where((v) => _asInt(v['caixaCodigo']) == caixaCodigo).toList();
      final activeIds = <int>{
        for (final v in ofCaixa)
          if (_cancelled(v) == false && _asInt(v['vendaCodigo']) != null)
            _asInt(v['vendaCodigo'])!,
      };

      final totals = <String, double>{};
      for (final f in formas) {
        final venda = _asInt(f['vendaCodigo']);
        if (venda == null || !activeIds.contains(venda)) continue;
        final amount = _asDouble(f['valorPagamento']) ?? 0;
        if (amount == 0) continue;
        final name = ((f['nomeFormaPagamento'] as String?)?.trim().isNotEmpty ?? false)
            ? (f['nomeFormaPagamento'] as String).trim()
            : ((f['tipoFormaPagamento'] as String?)?.trim().isNotEmpty ?? false)
                ? (f['tipoFormaPagamento'] as String).trim()
                : 'Outros';
        totals[name] = (totals[name] ?? 0) + amount;
      }

      final payments = [
        for (final e in totals.entries)
          ClosingPaymentLineDto(name: e.key.toUpperCase(), amount: e.value),
      ]..sort((a, b) => b.amount.compareTo(a.amount));

      final paymentsTotal = payments.fold<double>(0, (s, p) => s + p.amount);

      ofCaixa.sort((a, b) => '${b['dataHora']}'.compareTo('${a['dataHora']}'));
      final shown = ofCaixa.take(salesShownLimit).map((v) {
        final doc = (v['clienteCpfCnpj'] as String?)?.trim();
        final nota = (v['notaNumero'] as String?)?.trim();
        return ClosingSaleLineDto(
          soldAt: '${v['dataHora'] ?? ''}',
          clientDocument: (doc == null || doc.isEmpty) ? null : doc,
          invoiceNumber: (nota == null || nota.isEmpty) ? null : nota,
          total: _asDouble(v['totalVenda']) ?? 0,
          cancelled: _cancelled(v),
        );
      }).toList();

      return ClosingDetailDto(
        employeeName: employeeName,
        payments: payments,
        paymentsTotal: paymentsTotal,
        salesCount: ofCaixa.length,
        sales: shown,
      );
    } catch (_) {
      return const ClosingDetailDto(
        warning: 'Nao foi possivel consultar as vendas deste caixa no WebPosto.',
      );
    }
  }

  Future<String?> _employeeName(int? code, int empresaCodigo) async {
    if (code == null) return null;
    try {
      final rows = await _cached(
        'func|$code',
        () => _client.funcionarios(funcionarioCodigo: code),
      );
      Map<String, dynamic>? match;
      for (final row in rows) {
        if (_asInt(row['funcionarioCodigo']) != code) continue;
        match ??= row;
        if (_asInt(row['empresaCodigo']) == empresaCodigo) {
          match = row;
          break;
        }
      }
      final name = (match?['nome'] as String?)?.trim();
      return (name == null || name.isEmpty) ? null : name;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _cached(
    String key,
    Future<List<Map<String, dynamic>>> Function() load,
  ) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < _cacheFor) return hit.rows;
    final pending = _inflight[key];
    if (pending != null) return pending;

    final future = load();
    _inflight[key] = future;
    try {
      final rows = await future;
      _cache[key] = _CachedRows(DateTime.now(), rows);
      return rows;
    } finally {
      _inflight.remove(key);
    }
  }
}

class _CachedRows {
  _CachedRows(this.at, this.rows);
  final DateTime at;
  final List<Map<String, dynamic>> rows;
}

bool _cancelled(Map<String, dynamic> venda) {
  final flag = '${venda['cancelada'] ?? ''}'.toUpperCase();
  return flag == 'S' || flag == 'TRUE';
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
