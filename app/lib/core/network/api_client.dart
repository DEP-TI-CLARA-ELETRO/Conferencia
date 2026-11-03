import 'package:dio/dio.dart';

/// Em producao: `flutter build web --dart-define=API_URL=https://api.exemplo.com`
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  factory ApiException.from(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
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
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = apiBaseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token;
        if (t != null) options.headers['authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: (e, handler) {
        final data = e.response?.data;
        final code = data is Map ? data['code'] : null;
        final expired = e.response?.statusCode == 401 &&
            token != null &&
            (code == 'session_expired' || code == 'unauthenticated');
        if (expired) onSessionExpired?.call();
        handler.next(e);
      },
    ));
  }

  final Dio dio;

  /// Token da sessao atual (null = deslogado).
  String? token;

  /// Chamado quando o servidor recusa o token (sessao expirada/revogada).
  void Function()? onSessionExpired;
}
