import 'user_dto.dart';

/// Resposta do login: token opaco + usuario.
class SessionDto {
  const SessionDto({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final UserDto user;

  factory SessionDto.fromJson(Map<String, dynamic> json) => SessionDto(
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'user': user.toJson(),
      };
}
