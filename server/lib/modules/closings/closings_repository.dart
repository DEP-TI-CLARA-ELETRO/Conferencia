import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shared/shared.dart';

class ClosingsRepository {
  ClosingsRepository(this._db);
  final Pool<void> _db;

  Future<List<ClosingDto>> list({
    required DateTime from,
    required DateTime to,
    int? storeId,
    String? businessUnit,
  }) async {
    final fromDay = _ymd(from);
    final toDay = _ymd(to);

    final rows = await _db.execute(
      Sql.named('''
        SELECT
          c.id::text,
          c.store_id,
          s.name,
          c.connector,
          c.external_caixa_codigo,
          c.movement_date::text,
          c.shift_label,
          c.pdv_code,
          c.employee_code,
          c.opened_at,
          c.closed_at,
          c.closed,
          c.consolidated,
          c.apurado,
          c.diferenca,
          c.stage,
          c.payment_breakdown
        FROM cash_closings c
        JOIN stores s ON s.id = c.store_id
        WHERE c.movement_date >= @fromDay::date
          AND c.movement_date <= @toDay::date
          AND (@store::int IS NULL OR c.store_id = @store::int)
          AND (
            @bu::text IS NULL
            OR s.business_unit = @bu::text
          )
        ORDER BY c.movement_date DESC, s.name, c.external_caixa_codigo, c.shift_code NULLS LAST
      '''),
      parameters: {
        'fromDay': fromDay,
        'toDay': toDay,
        'store': storeId,
        'bu': businessUnit,
      },
    );

    return rows.map((r) {
      final pay = r[16];
      Map<String, dynamic> breakdown = {};
      if (pay is Map) {
        breakdown = Map<String, dynamic>.from(pay);
      } else if (pay is String) {
        breakdown = Map<String, dynamic>.from(jsonDecode(pay) as Map);
      }

      return ClosingDto(
        id: r[0] as String,
        storeId: r[1] as int,
        storeName: r[2] as String,
        connector: r[3] as String,
        caixaCodigo: r[4] as int,
        movementDate: (r[5] as String).substring(0, 10),
        shiftLabel: r[6] as String?,
        pdvCode: r[7] as int?,
        employeeCode: r[8] as int?,
        openedAt: (r[9] as DateTime?)?.toUtc().toIso8601String(),
        closedAt: (r[10] as DateTime?)?.toUtc().toIso8601String(),
        closed: r[11] as bool,
        consolidated: r[12] as bool,
        apurado: _asDouble(r[13]),
        diferenca: _asDouble(r[14]),
        stage: r[15] as String,
        paymentBreakdown: breakdown,
      );
    }).toList();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
