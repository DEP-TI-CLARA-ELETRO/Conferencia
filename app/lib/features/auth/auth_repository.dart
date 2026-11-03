import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

/// Fala com a API de auth e guarda/recupera o token no navegador.
class AuthRepository {
  AuthRepository(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  // Nome da chave na "gaveta" do navegador
  static const _tokenKey = 'session_token';

  /// Token já salvo (ou null).
  String? get savedToken => _prefs.getString(_tokenKey);

  /// POST /auth/login → salva token → devolve o usuário.
  Future<UserDto> login(String email, String password) async {
    try {
      final res = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password}, // corpo JSON
      );
      // res.data vem como Map dinâmico; fromJson monta SessionDto tipado
      final session = SessionDto.fromJson(res.data as Map<String, dynamic>);
      _api.token = session.token; // memória (próximas requests)
      await _prefs.setString(_tokenKey, session.token); // disco/navegador (F5)
      return session.user;
    } catch (e) {
      throw ApiException.from(e); // padroniza o erro para a UI
    }
  }

  /// Valida o token salvo. null = precisa fazer login de novo.
  Future<UserDto?> restore() async {
    final token = savedToken;
    if (token == null) return null;
    _api.token = token;
    try {
      final res = await _api.dio.get('/auth/me');
      return UserDto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiException.from(e);
      // 401 = sessão inválida → apaga token
      // Outros erros (rede) → NÃO apaga (pode ser API temporariamente fora)
      if (err.status == 401) await clearLocal();
      if (err.status == 401) return null;
      rethrow; // joga o erro para o controller tratar
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {
      // Mesmo se a API falhar, encerramos a sessão local
    }
    await clearLocal();
  }

  Future<void> clearLocal() async {
    _api.token = null;
    await _prefs.remove(_tokenKey);
  }
}
