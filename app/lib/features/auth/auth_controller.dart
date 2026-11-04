import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import 'auth_repository.dart';

/// Situação da autenticação no app.
enum AuthStatus { unknown, unauthenticated, authenticated }

/// "Foto" imutável do estado de auth (a UI observa isto).
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.busy = false,
  });

  final AuthStatus status;
  final UserDto? user;
  final String? error; // mensagem para mostrar no login
  final bool busy; // true = botão Entrar em loading
}

/// Sobrescrito em main() com a instância real de SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider nao inicializado'),
);

/// Cliente HTTP único do app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Repositório de auth (depende do cliente e das prefs).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Controller + estado: a tela faz watch disto.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Cérebro da autenticação: restore / login / logout.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final api = ref.read(apiClientProvider);
    // Se qualquer request receber sessão expirada, desloga e mostra mensagem
    api.onSessionExpired = () {
      ref.read(authRepositoryProvider).clearLocal();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Sua sessao expirou. Entre novamente.',
      );
    };
    // Agenda restore logo após o build (não faz rede DENTRO do build)
    Future.microtask(restore);
    return const AuthState(); // começa como unknown
  }

  // Atalho para o repositório
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Tenta recuperar sessão pelo token salvo.
  Future<void> restore() async {
    try {
      final user = await _repo.restore();
      // Operador ternário: user null? deslogado : autenticado
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    } catch (e) {
      // Qualquer outro erro (parse, rede crua, etc.) não pode deixar
      // o app eterno em /carregando (AuthStatus.unknown).
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e is ApiException ? e.message : 'Nao foi possivel validar a sessao.',
      );
    }
  }

  /// Chamado pela LoginPage ao clicar Entrar.
  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.unauthenticated, busy: true);
    try {
      final user = await _repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
