import 'package:dio/dio.dart';

/// URL base da API.
/// Em produção: flutter build web --dart-define=API_URL=https://api.exemplo.com
/// String.fromEnvironment lê essa constante de compilação; se não passar, usa localhost.
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

/// Erro amigável da API (mensagem + código + status HTTP).
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  /// Converte qualquer erro (principalmente DioException) em ApiException.
  factory ApiException.from(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      // Se o servidor mandou { "error": "...", "code": "..." }, usamos isso
      if (data is Map && data['error'] is String) {
        return ApiException(
          data['error'] as String,
          code: data['code'] as String?,
          status: error.response?.statusCode,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return ApiException('Nao foi possivel conectar ao servidor.', code: 'network');
      }
      return ApiException('Erro na comunicacao com o servidor.', status: error.response?.statusCode);
    }
    return ApiException('Erro inesperado.');
  }

  @override
  String toString() => message; // quando printar a exceção, mostra a mensagem
}

/// Cliente HTTP do app (pacote dio).
class ApiClient {
  ApiClient({String baseUrl = apiBaseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'accept': 'application/json'},
        )) {
    // Interceptor = "gancho" em toda request/resposta/erro
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Antes de enviar: se tem token, coloca Authorization: Bearer ...
        final t = token;
        if (t != null) options.headers['authorization'] = 'Bearer $t';
        handler.next(options); // continua o envio
      },
      onError: (e, handler) {
        final data = e.response?.data;
        final code = data is Map ? data['code'] : null;
        // Se o servidor disse que a sessão morreu, avisa o app
        final expired = e.response?.statusCode == 401 &&
            token != null &&
            (code == 'session_expired' || code == 'unauthenticated');
        if (expired) onSessionExpired?.call(); // ?.call = só chama se não for null
        handler.next(e);
      },
    ));
  }

  final Dio dio;

  /// Token da sessão atual (null = deslogado).
  String? token;

  /// Callback quando o servidor recusa o token.
  void Function()? onSessionExpired;
}
