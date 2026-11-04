/// Um fechamento de caixa (importado do WebPosto ou outro conector).
class ClosingDto {
  const ClosingDto({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.connector,
    required this.caixaCodigo,
    required this.movementDate,
    this.shiftLabel,
    this.pdvCode,
    this.employeeCode,
    this.openedAt,
    this.closedAt,
    required this.closed,
    required this.consolidated,
    this.apurado,
    this.diferenca,
    required this.stage,
    this.paymentBreakdown = const {},
  });

  final String id;
  final int storeId;
  final String storeName;
  final String connector;
  final int caixaCodigo;
  final String movementDate; // yyyy-MM-dd
  final String? shiftLabel;
  final int? pdvCode;
  final int? employeeCode;
  final String? openedAt;
  final String? closedAt;
  final bool closed;
  final bool consolidated;
  final double? apurado;
  final double? diferenca;
  final String stage;
  final Map<String, dynamic> paymentBreakdown;

  factory ClosingDto.fromJson(Map<String, dynamic> json) => ClosingDto(
        id: json['id'] as String,
        storeId: json['storeId'] as int,
        storeName: json['storeName'] as String? ?? '',
        connector: json['connector'] as String? ?? 'webposto',
        caixaCodigo: json['caixaCodigo'] as int,
        movementDate: json['movementDate'] as String,
        shiftLabel: json['shiftLabel'] as String?,
        pdvCode: json['pdvCode'] as int?,
        employeeCode: json['employeeCode'] as int?,
        openedAt: json['openedAt'] as String?,
        closedAt: json['closedAt'] as String?,
        closed: json['closed'] as bool? ?? false,
        consolidated: json['consolidated'] as bool? ?? false,
        apurado: (json['apurado'] as num?)?.toDouble(),
        diferenca: (json['diferenca'] as num?)?.toDouble(),
        stage: json['stage'] as String? ?? 'pdv_imported',
        paymentBreakdown: Map<String, dynamic>.from(
          json['paymentBreakdown'] as Map? ?? {},
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'storeName': storeName,
        'connector': connector,
        'caixaCodigo': caixaCodigo,
        'movementDate': movementDate,
        'shiftLabel': shiftLabel,
        'pdvCode': pdvCode,
        'employeeCode': employeeCode,
        'openedAt': openedAt,
        'closedAt': closedAt,
        'closed': closed,
        'consolidated': consolidated,
        'apurado': apurado,
        'diferenca': diferenca,
        'stage': stage,
        'paymentBreakdown': paymentBreakdown,
      };
}

/// Resultado de uma sincronização WebPosto.
class WebpostoSyncResultDto {
  const WebpostoSyncResultDto({
    required this.companiesUpserted,
    required this.closingsUpserted,
    required this.from,
    required this.to,
  });

  final int companiesUpserted;
  final int closingsUpserted;
  final String from;
  final String to;

  factory WebpostoSyncResultDto.fromJson(Map<String, dynamic> json) =>
      WebpostoSyncResultDto(
        companiesUpserted: json['companiesUpserted'] as int,
        closingsUpserted: json['closingsUpserted'] as int,
        from: json['from'] as String,
        to: json['to'] as String,
      );

  Map<String, dynamic> toJson() => {
        'companiesUpserted': companiesUpserted,
        'closingsUpserted': closingsUpserted,
        'from': from,
        'to': to,
      };
}
