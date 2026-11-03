import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';

import '../core/http.dart';
import '../modules/auth/auth_repository.dart';

const _userKey = 'auth.user';
const _sessionKey = 'auth.sessionId';

extension AuthContext on Request {
  UserDto get user => context[_userKey] as UserDto;
  String get sessionId => context[_sessionKey] as String;
}

String? bearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null || !header.toLowerCase().startsWith('bearer ')) return null;
  final token = header.substring(7).trim();
  return token.isEmpty ? null : token;
}

/// Exige sessao valida (`Authorization: Bearer token`).
Middleware requireAuth(AuthRepository repo) {
  return (inner) => (request) async {
        final token = bearerToken(request);
        if (token == null) return jsonError(401, 'Nao autenticado', code: 'unauthenticated');

        final session = await repo.findActiveSession(token);
        if (session == null) return jsonError(401, 'Sessao invalida ou expirada', code: 'session_expired');

        final user = await repo.loadUser(session.userId);
        if (user == null) return jsonError(401, 'Usuario inativo', code: 'unauthenticated');

        return inner(request.change(context: {
          _userKey: user,
          _sessionKey: session.id,
        }));
      };
}

/// Exige que o usuario autenticado tenha ao menos uma das permissoes.
/// Deve vir depois de [requireAuth].
Middleware requirePermission(Permission first, [Permission? second]) {
  return (inner) => (request) {
        final user = request.user;
        if (user.can(first) || (second != null && user.can(second))) {
          return inner(request);
        }
        return jsonError(403, 'Sem permissao', code: 'forbidden');
      };
}
