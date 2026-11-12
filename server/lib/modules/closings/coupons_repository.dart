import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shared/shared.dart';

class CouponsRepository {
  CouponsRepository(this._db);
  final Pool<void> _db;

  Future<ClosingDto?> findClosing(String closingId) async {
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
        WHERE c.id = @id::uuid
      '''),
      parameters: {'id': closingId},
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
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
      paymentBreakdown: _asMap(r[16]),
    );
  }

  Future<ClosingCouponDto> insertUploaded({
    required String closingId,
    required String storagePath,
    required String? originalFilename,
    required String? contentType,
    required String? createdBy,
  }) async {
    final rows = await _db.execute(
      Sql.named('''
        INSERT INTO closing_coupons (
          closing_id, storage_path, original_filename, content_type, status, created_by
        ) VALUES (
          @closing::uuid, @path, @name, @ctype, 'ocr_pending', @user::uuid
        )
        RETURNING id::text, created_at
      '''),
      parameters: {
        'closing': closingId,
        'path': storagePath,
        'name': originalFilename,
        'ctype': contentType,
        'user': createdBy,
      },
    );
    final r = rows.first;
    return ClosingCouponDto(
      id: r[0] as String,
      closingId: closingId,
      status: 'ocr_pending',
      originalFilename: originalFilename,
      contentType: contentType,
      createdAt: (r[1] as DateTime).toUtc().toIso8601String(),
    );
  }

  Future<void> saveOcrResult({
    required String couponId,
    required String status,
    required Map<String, double> proposed,
    required String? warning,
    required List<OcrRunInsert> runs,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE closing_coupons
        SET status = @status,
            proposed_values = @proposed::jsonb,
            ocr_warning = @warning,
            updated_at = now()
        WHERE id = @id::uuid
      '''),
      parameters: {
        'id': couponId,
        'status': status,
        'proposed': jsonEncode(proposed),
        'warning': warning,
      },
    );

    for (final run in runs) {
      await _db.execute(
        Sql.named('''
          INSERT INTO closing_coupon_ocr_runs (
            coupon_id, engine, raw_text, parsed_json, confidence, error
          ) VALUES (
            @coupon::uuid, @engine, @raw, @parsed::jsonb, @conf, @error
          )
        '''),
        parameters: {
          'coupon': couponId,
          'engine': run.engine,
          'raw': run.rawText,
          'parsed': jsonEncode(run.parsed),
          'conf': run.confidence,
          'error': run.error,
        },
      );
    }
  }

  Future<ClosingCouponDto?> findCoupon(String couponId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT
          id::text,
          closing_id::text,
          storage_path,
          original_filename,
          content_type,
          status,
          proposed_values,
          confirmed_values,
          match_result,
          ocr_warning,
          created_at,
          confirmed_at
        FROM closing_coupons
        WHERE id = @id::uuid
      '''),
      parameters: {'id': couponId},
    );
    if (rows.isEmpty) return null;
    final coupon = _mapCoupon(rows.first);
    final runs = await _listRuns(couponId);
    return ClosingCouponDto(
      id: coupon.id,
      closingId: coupon.closingId,
      status: coupon.status,
      originalFilename: coupon.originalFilename,
      contentType: coupon.contentType,
      proposedValues: coupon.proposedValues,
      confirmedValues: coupon.confirmedValues,
      matchResult: coupon.matchResult,
      ocrWarning: coupon.ocrWarning,
      ocrRuns: runs,
      createdAt: coupon.createdAt,
      confirmedAt: coupon.confirmedAt,
    );
  }

  Future<String?> storagePathOf(String couponId) async {
    final rows = await _db.execute(
      Sql.named('SELECT storage_path FROM closing_coupons WHERE id = @id::uuid'),
      parameters: {'id': couponId},
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as String;
  }

  Future<List<ClosingCouponDto>> listByClosing(String closingId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT
          id::text,
          closing_id::text,
          storage_path,
          original_filename,
          content_type,
          status,
          proposed_values,
          confirmed_values,
          match_result,
          ocr_warning,
          created_at,
          confirmed_at
        FROM closing_coupons
        WHERE closing_id = @closing::uuid
        ORDER BY created_at DESC
      '''),
      parameters: {'closing': closingId},
    );
    final out = <ClosingCouponDto>[];
    for (final r in rows) {
      final base = _mapCoupon(r);
      final runs = await _listRuns(base.id);
      out.add(
        ClosingCouponDto(
          id: base.id,
          closingId: base.closingId,
          status: base.status,
          originalFilename: base.originalFilename,
          contentType: base.contentType,
          proposedValues: base.proposedValues,
          confirmedValues: base.confirmedValues,
          matchResult: base.matchResult,
          ocrWarning: base.ocrWarning,
          ocrRuns: runs,
          createdAt: base.createdAt,
          confirmedAt: base.confirmedAt,
        ),
      );
    }
    return out;
  }

  Future<ClosingCouponDto> confirm({
    required String couponId,
    required Map<String, double> values,
    required CouponMatchResultDto match,
    required String? confirmedBy,
  }) async {
    final rows = await _db.execute(
      Sql.named('''
        UPDATE closing_coupons
        SET status = 'confirmed',
            confirmed_values = @values::jsonb,
            match_result = @match::jsonb,
            confirmed_by = @user::uuid,
            confirmed_at = now(),
            updated_at = now()
        WHERE id = @id::uuid
        RETURNING
          id::text,
          closing_id::text,
          storage_path,
          original_filename,
          content_type,
          status,
          proposed_values,
          confirmed_values,
          match_result,
          ocr_warning,
          created_at,
          confirmed_at
      '''),
      parameters: {
        'id': couponId,
        'values': jsonEncode(values),
        'match': jsonEncode(match.toJson()),
        'user': confirmedBy,
      },
    );
    final base = _mapCoupon(rows.first);
    final runs = await _listRuns(couponId);
    return ClosingCouponDto(
      id: base.id,
      closingId: base.closingId,
      status: base.status,
      originalFilename: base.originalFilename,
      contentType: base.contentType,
      proposedValues: base.proposedValues,
      confirmedValues: base.confirmedValues,
      matchResult: base.matchResult,
      ocrWarning: base.ocrWarning,
      ocrRuns: runs,
      createdAt: base.createdAt,
      confirmedAt: base.confirmedAt,
    );
  }

  Future<List<CouponOcrRunDto>> _listRuns(String couponId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT engine, raw_text, parsed_json, confidence, error
        FROM closing_coupon_ocr_runs
        WHERE coupon_id = @id::uuid
        ORDER BY created_at
      '''),
      parameters: {'id': couponId},
    );
    return rows.map((r) {
      final parsedMap = _asMap(r[2]);
      final parsed = <String, double>{};
      for (final e in parsedMap.entries) {
        final v = e.value;
        if (v is num) parsed[e.key] = v.toDouble();
      }
      return CouponOcrRunDto(
        engine: r[0] as String,
        rawText: r[1] as String?,
        parsed: parsed,
        confidence: _asDouble(r[3]),
        error: r[4] as String?,
      );
    }).toList();
  }

  ClosingCouponDto _mapCoupon(ResultRow r) {
    final proposed = CouponPaymentValues.fromJson(_asMap(r[6]));
    final confirmedRaw = r[7];
    final matchRaw = r[8];
    return ClosingCouponDto(
      id: r[0] as String,
      closingId: r[1] as String,
      status: r[5] as String,
      originalFilename: r[3] as String?,
      contentType: r[4] as String?,
      proposedValues: proposed,
      confirmedValues: confirmedRaw == null
          ? null
          : CouponPaymentValues.fromJson(_asMap(confirmedRaw)),
      matchResult: matchRaw == null
          ? null
          : CouponMatchResultDto.fromJson(_asMap(matchRaw)),
      ocrWarning: r[9] as String?,
      createdAt: (r[10] as DateTime?)?.toUtc().toIso8601String(),
      confirmedAt: (r[11] as DateTime?)?.toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    }
    return {};
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class OcrRunInsert {
  const OcrRunInsert({
    required this.engine,
    this.rawText,
    this.parsed = const {},
    this.confidence,
    this.error,
  });

  final String engine;
  final String? rawText;
  final Map<String, double> parsed;
  final double? confidence;
  final String? error;
}
