import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shared/shared.dart';

import '../../core/security.dart';

class UserCredentials {
  UserCredentials(this.id, this.passwordHash, this.active);
  final String id;
  final String passwordHash;
  final bool active;
}

class SessionInfo {
  SessionInfo(this.id, this.userId);
  final String id;
  final String userId;
}

class AuthRepository {
  AuthRepository(this._db);

  final Pool<void> _db;

  Future<UserCredentials?> findCredentials(String email) async {
    final r = await _db.execute(
      Sql.named('SELECT id::text, password_hash, active FROM users WHERE lower(email) = lower(@email)'),
      parameters: {'email': email},
    );
    if (r.isEmpty) return null;
    final row = r.first;
    return UserCredentials(row[0] as String, row[1] as String, row[2] as bool);
  }

  Future<bool> userExists(String email) async {
    final r = await _db.execute(
      Sql.named('SELECT 1 FROM users WHERE lower(email) = lower(@email)'),
      parameters: {'email': email},
    );
    return r.isNotEmpty;
  }

  Future<String> createUser({
    required String email,
    required String name,
    required String passwordHash,
    String? registration,
  }) async {
    final r = await _db.execute(
      Sql.named('''
        INSERT INTO users (email, name, registration, password_hash)
        VALUES (@email, @name, @reg, @hash) RETURNING id::text
      '''),
      parameters: {'email': email, 'name': name, 'reg': registration, 'hash': passwordHash},
    );
    return r.first[0] as String;
  }

  Future<void> assignRole(String userId, String roleCode, {int? storeId}) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO user_roles (user_id, role_id, store_id)
        SELECT @uid::uuid, id, @store FROM roles WHERE code = @role
        ON CONFLICT DO NOTHING
      '''),
      parameters: {'uid': userId, 'role': roleCode, 'store': storeId},
    );
  }

  /// Monta o usuario com perfis, permissoes e lojas acessiveis.
  Future<UserDto?> loadUser(String userId) async {
    final u = await _db.execute(
      Sql.named('SELECT id::text, email, name, registration FROM users WHERE id = @id::uuid AND active'),
      parameters: {'id': userId},
    );
    if (u.isEmpty) return null;
    final row = u.first;

    final roles = await _db.execute(
      Sql.named('''
        SELECT DISTINCT r.code FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id WHERE ur.user_id = @id::uuid
      '''),
      parameters: {'id': userId},
    );

    final perms = await _db.execute(
      Sql.named('''
        SELECT DISTINCT p.code FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = @id::uuid
      '''),
      parameters: {'id': userId},
    );

    // store_id NULL em user_roles = acesso a todas as lojas ativas
    final stores = await _db.execute(
      Sql.named('''
        SELECT DISTINCT s.id, s.code, s.name FROM stores s
        WHERE s.active AND (
          EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = @id::uuid AND ur.store_id IS NULL)
          OR s.id IN (SELECT store_id FROM user_roles WHERE user_id = @id::uuid AND store_id IS NOT NULL)
        )
        ORDER BY s.code
      '''),
      parameters: {'id': userId},
    );

    return UserDto(
      id: row[0] as String,
      email: row[1] as String,
      name: row[2] as String,
      registration: row[3] as String?,
      roles: roles.map((r) => Role.fromCode(r[0] as String)).whereType<Role>().toList(),
      permissions: perms.map((r) => Permission.fromCode(r[0] as String)).whereType<Permission>().toSet(),
      stores: stores
          .map((r) => StoreDto(id: r[0] as int, code: r[1] as String, name: r[2] as String))
          .toList(),
    );
  }

  /// Cria a sessao e devolve o token em texto (so aparece aqui, nunca e gravado).
  Future<({String token, DateTime expiresAt})> createSession(
    String userId, {
    required Duration ttl,
    String? ip,
    String? userAgent,
  }) async {
    final token = generateToken();
    final expiresAt = DateTime.now().toUtc().add(ttl);
    await _db.execute(
      Sql.named('''
        INSERT INTO sessions (user_id, token_hash, expires_at, ip, user_agent)
        VALUES (@uid::uuid, @hash, @exp, @ip, @ua)
      '''),
      parameters: {
        'uid': userId,
        'hash': hashToken(token),
        'exp': expiresAt,
        'ip': ip,
        'ua': userAgent,
      },
    );
    await _db.execute(
      Sql.named('UPDATE users SET last_login_at = now() WHERE id = @id::uuid'),
      parameters: {'id': userId},
    );
    return (token: token, expiresAt: expiresAt);
  }

  Future<SessionInfo?> findActiveSession(String token) async {
    final r = await _db.execute(
      Sql.named('''
        SELECT id::text, user_id::text FROM sessions
        WHERE token_hash = @hash AND revoked_at IS NULL AND expires_at > now()
      '''),
      parameters: {'hash': hashToken(token)},
    );
    if (r.isEmpty) return null;
    return SessionInfo(r.first[0] as String, r.first[1] as String);
  }

  Future<void> revokeSession(String sessionId) async {
    await _db.execute(
      Sql.named('UPDATE sessions SET revoked_at = now() WHERE id = @id::uuid'),
      parameters: {'id': sessionId},
    );
  }

  Future<void> audit(
    String action, {
    String? userId,
    String? ip,
    Map<String, Object?>? details,
  }) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO audit_log (user_id, action, details, ip)
        VALUES (@uid::uuid, @action, @details::jsonb, @ip)
      '''),
      parameters: {
        'uid': userId,
        'action': action,
        'details': details == null ? null : jsonEncode(details),
        'ip': ip,
      },
    );
  }
}
