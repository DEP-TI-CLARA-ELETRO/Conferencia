import '../enums/business_unit.dart';

/// Ficha de uma loja / unidade.
class StoreDto {
  const StoreDto({
    required this.id,
    required this.code,
    required this.name,
    this.businessUnit = BusinessUnit.outros,
  });

  final int id;
  final String code;
  final String name;
  final BusinessUnit businessUnit;

  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        businessUnit: BusinessUnit.fromCode(json['businessUnit'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'businessUnit': businessUnit.code,
      };
}
