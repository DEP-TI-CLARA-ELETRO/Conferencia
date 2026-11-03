import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';

import '../core/http.dart';
import '../modules/auth/auth_repository.dart';

// Chaves usadas no "context" do Request (uma caixinha de dados por pedido)
const _userKey = 'auth.user';
const _sessionKey = 'auth.sessionId';

/// Extensão: acrescenta getters úteis em Request.
/// Depois do requireAuth, dá para fazer request.user e request.sessionId.
extension AuthContext on Request {
  UserDto get user => context[_userKey] as UserDto;
  String get sessionId => context[_sessionKey] as String;
}

/// Extrai o token do cabeçalho: Authorization: Bearer xxxxx
String? bearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null || !header.toLowerCase().startsWith('bearer ')) return null;
  final token = header.substring(7).trim(); // corta "Bearer "
  return token.isEmpty ? null : token;
}

/// Exige sessão válida (`Authorization: Bearer token`).
/// Se ok, grava user e sessionId no context e segue para a rota.
Middleware requireAuth(AuthRepository repo) {
  return (inner) => (request) async {
        final token = bearerToken(request);
        if (token == null) {
          return jsonError(401, 'Nao autenticado', code: 'unauthenticated');
        }

        final session = await repo.findActiveSession(token);
        if (session == null) {
          return jsonError(401, 'Sessao invalida ou expirada', code: 'session_expired');
        }

        final user = await repo.loadUser(session.userId);
        if (user == null) {
          return jsonError(401, 'Usuario inativo', code: 'unauthenticated');
        }

        // request.change(context: ...) = cria um Request novo com dados extras
        return inner(request.change(context: {
          _userKey: user,
          _sessionKey: session.id,
        }));
      };
}

/// Exige que o usuário já autenticado tenha ao menos uma das permissões.
/// Deve vir DEPOIS de [requireAuth].
Middleware requirePermission(Permission first, [Permission? second]) {
  // [Permission? second] = parâmetro opcional posicional
  return (inner) => (request) {
        final user = request.user; // vem da extension AuthContext
        if (user.can(first) || (second != null && user.can(second))) {
          return inner(request);
        }
        return jsonError(403, 'Sem permissao', code: 'forbidden');
      };
}
