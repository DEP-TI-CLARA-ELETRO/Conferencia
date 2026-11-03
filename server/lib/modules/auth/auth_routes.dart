import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../config/config.dart';
import '../../core/http.dart';
import '../../core/security.dart';
import '../../middleware/auth_middleware.dart';
import 'auth_repository.dart';

class AuthRoutes {
  AuthRoutes(this._repo, this._config);

  final AuthRepository _repo;
  final AppConfig _config;

  // Limite simples em memoria: 5 falhas / 10 min por ip+email.
  final Map<String, List<DateTime>> _failures = {};

  Router get router {
    final r = Router();
    final auth = requireAuth(_repo);
    r.post('/login', _login);
    r.post('/logout', const Pipeline().addMiddleware(auth).addHandler(_logout));
    r.get('/me', const Pipeline().addMiddleware(auth).addHandler(_me));
    return r;
  }

  bool _blocked(String key) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    final list = (_failures[key] ?? [])..removeWhere((t) => t.isBefore(cutoff));
    _failures[key] = list;
    return list.length >= 5;
  }

  Future<Response> _login(Request request) async {
    final body = await readJson(request);
    final email = (body?['email'] as String?)?.trim() ?? '';
    final password = body?['password'] as String? ?? '';
    if (email.isEmpty || password.isEmpty) {
      return jsonError(400, 'Informe e-mail e senha', code: 'invalid_request');
    }

    final ip = clientIp(request);
    final key = '${ip ?? '-'}|${email.toLowerCase()}';
    if (_blocked(key)) {
      return jsonError(429, 'Muitas tentativas. Tente novamente em alguns minutos.', code: 'too_many_attempts');
    }

    final creds = await _repo.findCredentials(email);
    // Sempre roda o bcrypt para nao revelar se o e-mail existe pelo tempo de resposta.
    final ok = verifyPassword(password, creds?.passwordHash ?? dummyPasswordHash);

    if (creds == null || !creds.active || !ok) {
      _failures.putIfAbsent(key, () => []).add(DateTime.now());
      await _repo.audit('login_failed', ip: ip, details: {'email': email});
      return jsonError(401, 'E-mail ou senha invalidos', code: 'invalid_credentials');
    }

    _failures.remove(key);
    final user = await _repo.loadUser(creds.id);
    if (user == null) return jsonError(401, 'Usuario inativo', code: 'invalid_credentials');

    final s = await _repo.createSession(
      creds.id,
      ttl: _config.sessionTtl,
      ip: ip,
      userAgent: request.headers['user-agent'],
    );
    await _repo.audit('login', userId: creds.id, ip: ip);

    return jsonOk(SessionDto(token: s.token, expiresAt: s.expiresAt, user: user).toJson());
  }

  Future<Response> _logout(Request request) async {
    await _repo.revokeSession(request.sessionId);
    await _repo.audit('logout', userId: request.user.id, ip: clientIp(request));
    return jsonOk({'ok': true});
  }

  Future<Response> _me(Request request) async => jsonOk(request.user.toJson());
}
