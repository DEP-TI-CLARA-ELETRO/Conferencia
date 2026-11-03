class StoreDto {
  const StoreDto({required this.id, required this.code, required this.name});

  final int id;
  final String code;
  final String name;

  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};
}
