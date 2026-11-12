import 'package:shared/shared.dart';

import 'coupon_payment_keys.dart';

/// Cruza valores confirmados do cupom com payment_breakdown / apurado do ERP.
class CouponMatchService {
  CouponMatchResultDto match({
    required Map<String, dynamic> paymentBreakdown,
    required Map<String, double> scanned,
    double? closingApurado,
  }) {
    final expected = <String, double>{};
    for (final e in paymentBreakdown.entries) {
      final v = e.value;
      if (v is Map) {
        final apurado = v['apurado'] ?? v['apresentado'];
        if (apurado is num) expected[e.key] = apurado.toDouble();
      } else if (v is num) {
        expected[e.key] = v.toDouble();
      }
    }

    final keys = {
      ...CouponPaymentKeys.ordered.where((k) => expected.containsKey(k) || scanned.containsKey(k)),
      ...expected.keys,
      ...scanned.keys,
    };

    final lines = <CouponMatchLineDto>[];
    var allOk = true;
    for (final key in keys) {
      final exp = expected[key];
      final sc = scanned[key];
      if (exp == null && sc == null) continue;
      final diff = _round2((sc ?? 0) - (exp ?? 0));
      final ok = exp != null && sc != null && diff.abs() < 0.015;
      if (!ok) allOk = false;
      lines.add(
        CouponMatchLineDto(
          key: key,
          label: CouponPaymentKeys.labels[key] ?? key,
          expected: exp,
          scanned: sc,
          diff: diff,
          ok: ok,
        ),
      );
    }

    final scannedTotal = scanned.values.fold(0.0, (a, b) => a + b);
    final expectedTotal = expected.isNotEmpty
        ? expected.values.fold(0.0, (a, b) => a + b)
        : closingApurado;
    final totalDiff = expectedTotal == null ? null : _round2(scannedTotal - expectedTotal);
    if (totalDiff != null && totalDiff.abs() >= 0.015) allOk = false;
    if (lines.isEmpty) allOk = false;

    return CouponMatchResultDto(
      ok: allOk,
      lines: lines,
      expectedTotal: expectedTotal == null ? null : _round2(expectedTotal),
      scannedTotal: _round2(scannedTotal),
      totalDiff: totalDiff,
    );
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100;
}
