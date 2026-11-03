import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  static const _tokenKey = 'session_token';

  String? get savedToken => _prefs.getString(_tokenKey);

  Future<UserDto> login(String email, String password) async {
    try {
      final res = await _api.dio.post('/auth/login', data: {'email': email, 'password': password});
      final session = SessionDto.fromJson(res.data as Map<String, dynamic>);
      _api.token = session.token;
      await _prefs.setString(_tokenKey, session.token);
      return session.user;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Valida o token salvo no navegador. Devolve null se nao houver sessao valida.
  Future<UserDto?> restore() async {
    final token = savedToken;
    if (token == null) return null;
    _api.token = token;
    try {
      final res = await _api.dio.get('/auth/me');
      return UserDto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiException.from(e);
      // Servidor fora do ar nao deve apagar a sessao salva; 401 sim.
      if (err.status == 401) await clearLocal();
      if (err.status == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {
      // Mesmo que falhe, a sessao local e encerrada.
    }
    await clearLocal();
  }

  Future<void> clearLocal() async {
    _api.token = null;
    await _prefs.remove(_tokenKey);
  }
}
