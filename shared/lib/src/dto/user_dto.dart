import '../enums/permission.dart';
import '../enums/role.dart';
import 'store_dto.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.registration,
    this.roles = const [],
    this.permissions = const {},
    this.stores = const [],
  });

  final String id;
  final String email;
  final String name;
  final String? registration;
  final List<Role> roles;
  final Set<Permission> permissions;

  /// Lojas acessiveis ao usuario.
  final List<StoreDto> stores;

  bool can(Permission p) => permissions.contains(p);

  /// Texto curto para exibir sob o nome (ex.: "Fiscal de Caixa").
  String get roleLabel => roles.isEmpty ? '' : roles.first.label;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList();
    if (list.length == 1) return list.first[0].toUpperCase();
    return (list.first[0] + list.last[0]).toUpperCase();
  }

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        registration: json['registration'] as String?,
        roles: (json['roles'] as List? ?? [])
            .map((e) => Role.fromCode(e as String))
            .whereType<Role>()
            .toList(),
        permissions: (json['permissions'] as List? ?? [])
            .map((e) => Permission.fromCode(e as String))
            .whereType<Permission>()
            .toSet(),
        stores: (json['stores'] as List? ?? [])
            .map((e) => StoreDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'registration': registration,
        'roles': roles.map((e) => e.code).toList(),
        'permissions': permissions.map((e) => e.code).toList(),
        'stores': stores.map((e) => e.toJson()).toList(),
      };
}
