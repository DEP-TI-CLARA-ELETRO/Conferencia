import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// URL via --dart-define=API_URL=...; se vazio, escolhe por plataforma.
const _definedApiUrl = String.fromEnvironment('API_URL');

/// Web no PC → localhost. Web no celular (mesmo Wi‑Fi) → host da página :8080.
/// Emulador Android → 10.0.2.2. Override: --dart-define=API_URL=http://IP:8080
String resolveApiBaseUrl() {
  if (_definedApiUrl.isNotEmpty) return _definedApiUrl;
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
      return 'http://$host:8080';
    }
    return 'http://localhost:8080';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// Mantido para quem importa o nome antigo; prefira [resolveApiBaseUrl].
String get apiBaseUrl => resolveApiBaseUrl();

/// Erro amigável da API (mensagem + código + status HTTP).
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
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ApiException(
          'A operacao demorou demais. Tente um periodo menor ou tente de novo.',
          code: 'timeout',
        );
      }
      return ApiException('Erro na comunicacao com o servidor.', status: error.response?.statusCode);
    }
    return ApiException('Erro inesperado.');
  }

  @override
  String toString() => message;
}

/// Cliente HTTP do app (pacote dio).
class ApiClient {
  ApiClient({String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? resolveApiBaseUrl(),
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

  String? token;

  void Function()? onSessionExpired;
}
