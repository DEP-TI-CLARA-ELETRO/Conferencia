/// Detalhe de um caixa: formas de pagamento e vendas do WebPosto.
class ClosingDetailDto {
  const ClosingDetailDto({
    this.employeeName,
    this.payments = const [],
    this.paymentsTotal = 0,
    this.salesCount = 0,
    this.sales = const [],
    this.warning,
  });

  final String? employeeName;
  final List<ClosingPaymentLineDto> payments;
  final double paymentsTotal;
  final int salesCount;
  final List<ClosingSaleLineDto> sales;
  final String? warning;

  factory ClosingDetailDto.fromJson(Map<String, dynamic> json) => ClosingDetailDto(
        employeeName: json['employeeName'] as String?,
        payments: [
          for (final item in json['payments'] as List? ?? [])
            if (item is Map)
              ClosingPaymentLineDto.fromJson(Map<String, dynamic>.from(item)),
        ],
        paymentsTotal: _asDouble(json['paymentsTotal']) ?? 0,
        salesCount: json['salesCount'] as int? ?? 0,
        sales: [
          for (final item in json['sales'] as List? ?? [])
            if (item is Map)
              ClosingSaleLineDto.fromJson(Map<String, dynamic>.from(item)),
        ],
        warning: json['warning'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'employeeName': employeeName,
        'payments': payments.map((e) => e.toJson()).toList(),
        'paymentsTotal': paymentsTotal,
        'salesCount': salesCount,
        'sales': sales.map((e) => e.toJson()).toList(),
        'warning': warning,
      };
}

class ClosingPaymentLineDto {
  const ClosingPaymentLineDto({required this.name, required this.amount});

  final String name;
  final double amount;

  factory ClosingPaymentLineDto.fromJson(Map<String, dynamic> json) =>
      ClosingPaymentLineDto(
        name: json['name'] as String? ?? 'Outros',
        amount: _asDouble(json['amount']) ?? 0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class ClosingSaleLineDto {
  const ClosingSaleLineDto({
    required this.soldAt,
    this.clientDocument,
    this.invoiceNumber,
    required this.total,
    required this.cancelled,
  });

  final String soldAt;
  final String? clientDocument;
  final String? invoiceNumber;
  final double total;
  final bool cancelled;

  factory ClosingSaleLineDto.fromJson(Map<String, dynamic> json) =>
      ClosingSaleLineDto(
        soldAt: json['soldAt'] as String? ?? '',
        clientDocument: json['clientDocument'] as String?,
        invoiceNumber: json['invoiceNumber'] as String?,
        total: _asDouble(json['total']) ?? 0,
        cancelled: json['cancelled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'soldAt': soldAt,
        'clientDocument': clientDocument,
        'invoiceNumber': invoiceNumber,
        'total': total,
        'cancelled': cancelled,
      };
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
