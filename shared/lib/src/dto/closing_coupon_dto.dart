/// Valores por forma de pagamento extraídos/confirmados do cupom.
class CouponPaymentValues {
  const CouponPaymentValues(this.amounts);

  final Map<String, double> amounts;

  factory CouponPaymentValues.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CouponPaymentValues({});
    final out = <String, double>{};
    for (final e in json.entries) {
      final v = e.value;
      if (v is num) out[e.key] = v.toDouble();
      if (v is String) {
        final n = double.tryParse(v.replaceAll(',', '.'));
        if (n != null) out[e.key] = n;
      }
    }
    return CouponPaymentValues(out);
  }

  Map<String, dynamic> toJson() => {
        for (final e in amounts.entries) e.key: e.value,
      };

  double get total => amounts.values.fold(0.0, (a, b) => a + b);
}

/// Uma linha do cruzamento cupom × ERP.
class CouponMatchLineDto {
  const CouponMatchLineDto({
    required this.key,
    required this.label,
    this.expected,
    this.scanned,
    required this.diff,
    required this.ok,
  });

  final String key;
  final String label;
  final double? expected;
  final double? scanned;
  final double diff;
  final bool ok;

  factory CouponMatchLineDto.fromJson(Map<String, dynamic> json) => CouponMatchLineDto(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        expected: (json['expected'] as num?)?.toDouble(),
        scanned: (json['scanned'] as num?)?.toDouble(),
        diff: (json['diff'] as num?)?.toDouble() ?? 0,
        ok: json['ok'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'expected': expected,
        'scanned': scanned,
        'diff': diff,
        'ok': ok,
      };
}

class CouponMatchResultDto {
  const CouponMatchResultDto({
    required this.ok,
    required this.lines,
    this.expectedTotal,
    this.scannedTotal,
    this.totalDiff,
  });

  final bool ok;
  final List<CouponMatchLineDto> lines;
  final double? expectedTotal;
  final double? scannedTotal;
  final double? totalDiff;

  factory CouponMatchResultDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CouponMatchResultDto(ok: false, lines: []);
    }
    final raw = json['lines'] as List? ?? [];
    return CouponMatchResultDto(
      ok: json['ok'] as bool? ?? false,
      lines: raw
          .whereType<Map>()
          .map((e) => CouponMatchLineDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      expectedTotal: (json['expectedTotal'] as num?)?.toDouble(),
      scannedTotal: (json['scannedTotal'] as num?)?.toDouble(),
      totalDiff: (json['totalDiff'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'lines': lines.map((e) => e.toJson()).toList(),
        'expectedTotal': expectedTotal,
        'scannedTotal': scannedTotal,
        'totalDiff': totalDiff,
      };
}

class CouponOcrRunDto {
  const CouponOcrRunDto({
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

  factory CouponOcrRunDto.fromJson(Map<String, dynamic> json) {
    final parsedRaw = json['parsed'] as Map? ?? json['parsedJson'] as Map? ?? {};
    final parsed = <String, double>{};
    for (final e in parsedRaw.entries) {
      final v = e.value;
      if (v is num) parsed['${e.key}'] = v.toDouble();
    }
    return CouponOcrRunDto(
      engine: json['engine'] as String? ?? '',
      rawText: json['rawText'] as String?,
      parsed: parsed,
      confidence: (json['confidence'] as num?)?.toDouble(),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'engine': engine,
        'rawText': rawText,
        'parsed': parsed,
        'confidence': confidence,
        'error': error,
      };
}

class ClosingCouponDto {
  const ClosingCouponDto({
    required this.id,
    required this.closingId,
    required this.status,
    this.originalFilename,
    this.contentType,
    this.proposedValues = const CouponPaymentValues({}),
    this.confirmedValues,
    this.matchResult,
    this.ocrWarning,
    this.ocrRuns = const [],
    this.createdAt,
    this.confirmedAt,
  });

  final String id;
  final String closingId;
  final String status;
  final String? originalFilename;
  final String? contentType;
  final CouponPaymentValues proposedValues;
  final CouponPaymentValues? confirmedValues;
  final CouponMatchResultDto? matchResult;
  final String? ocrWarning;
  final List<CouponOcrRunDto> ocrRuns;
  final String? createdAt;
  final String? confirmedAt;

  factory ClosingCouponDto.fromJson(Map<String, dynamic> json) {
    final confirmed = json['confirmedValues'];
    final match = json['matchResult'];
    final runs = json['ocrRuns'] as List? ?? [];
    return ClosingCouponDto(
      id: json['id'] as String,
      closingId: json['closingId'] as String,
      status: json['status'] as String? ?? 'uploaded',
      originalFilename: json['originalFilename'] as String?,
      contentType: json['contentType'] as String?,
      proposedValues: CouponPaymentValues.fromJson(
        (json['proposedValues'] as Map?)?.cast<String, dynamic>(),
      ),
      confirmedValues: confirmed is Map
          ? CouponPaymentValues.fromJson(Map<String, dynamic>.from(confirmed))
          : null,
      matchResult: match is Map
          ? CouponMatchResultDto.fromJson(Map<String, dynamic>.from(match))
          : null,
      ocrWarning: json['ocrWarning'] as String?,
      ocrRuns: runs
          .whereType<Map>()
          .map((e) => CouponOcrRunDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: json['createdAt'] as String?,
      confirmedAt: json['confirmedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'closingId': closingId,
        'status': status,
        'originalFilename': originalFilename,
        'contentType': contentType,
        'proposedValues': proposedValues.toJson(),
        'confirmedValues': confirmedValues?.toJson(),
        'matchResult': matchResult?.toJson(),
        'ocrWarning': ocrWarning,
        'ocrRuns': ocrRuns.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'confirmedAt': confirmedAt,
      };
}
