import '../enums/permission.dart';
import '../enums/role.dart';
import 'store_dto.dart';

/// Ficha do usuário autenticado (o que a API devolve e o app guarda em memória).
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.registration, // opcional (matrícula); se não passar, fica null
    this.roles = const [], // valor padrão: lista vazia
    this.permissions = const {}, // valor padrão: conjunto vazio
    this.stores = const [],
  });

  final String id;
  final String email;
  final String name;
  final String? registration; // String? = texto OU null
  final List<Role> roles; // lista de perfis
  final Set<Permission> permissions; // conjunto (sem duplicatas) de permissões

  /// Lojas que este usuário pode ver/usar.
  final List<StoreDto> stores;

  /// Atalho: "este usuário pode fazer a permissão p?"
  /// => é função de UMA LINHA (return implícito).
  bool can(Permission p) => permissions.contains(p);

  /// Texto curto sob o nome (ex.: "Fiscal de Caixa").
  /// get = propriedade calculada (não é campo guardado; calcula na hora).
  String get roleLabel => roles.isEmpty ? '' : roles.first.label;

  /// Iniciais para o avatar (ex.: "Maria Silva" -> "MS").
  String get initials {
    // trim = tira espaços das pontas; split = quebra por espaços; where = filtra vazios
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList(); // transforma o iterável em List
    if (list.length == 1) return list.first[0].toUpperCase(); // só 1 nome: 1 letra
    // primeiro [0] da primeira palavra + primeiro [0] da última palavra
    return (list.first[0] + list.last[0]).toUpperCase();
  }

  /// Monta UserDto a partir do JSON da API.
  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        registration: json['registration'] as String?,
        // (lista ?? []) = se vier null, use lista vazia
        // .map = transforma cada item; whereType = descarta nulls do fromCode
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

  /// UserDto -> Map para enviar/serializar.
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'registration': registration,
        'roles': roles.map((e) => e.code).toList(), // Role -> "fiscal"
        'permissions': permissions.map((e) => e.code).toList(),
        'stores': stores.map((e) => e.toJson()).toList(),
      };
}
