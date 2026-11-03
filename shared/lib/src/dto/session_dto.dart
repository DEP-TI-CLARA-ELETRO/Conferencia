import 'user_dto.dart';

/// Resposta do login: o "crachá" (token) + até quando vale + dados do usuário.
class SessionDto {
  const SessionDto({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token; // texto secreto da sessão (Bearer)
  final DateTime expiresAt; // data/hora de expiração
  final UserDto user; // quem está logado

  factory SessionDto.fromJson(Map<String, dynamic> json) => SessionDto(
        token: json['token'] as String,
        // DateTime.parse lê uma string ISO (ex.: 2026-11-03T12:00:00.000Z)
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        // toUtc + toIso8601String = formato padrão internacional de data
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'user': user.toJson(),
      };
}
