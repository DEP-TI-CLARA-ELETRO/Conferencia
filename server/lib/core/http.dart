import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

// Cabeçalho padrão: resposta é JSON em UTF-8
const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// Resposta de sucesso (ou outro status) com corpo JSON.
Response jsonOk(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// Resposta de erro padronizada: { "error": "...", "code": "..." }
Response jsonError(int status, String message, {String? code}) => Response(
      status,
      // 'code': ?code  = só inclui a chave se code não for null (Dart moderno)
      body: jsonEncode({'error': message, 'code': ?code}),
      headers: _jsonHeaders,
    );

/// Lê o corpo do pedido HTTP e tenta virar um Map (objeto JSON).
/// Devolve null se estiver vazio, inválido ou não for objeto.
Future<Map<String, dynamic>?> readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    // Só aceitamos objeto { ... }, não lista [ ... ]
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Tenta descobrir o IP de quem chamou (útil no audit_log).
String? clientIp(Request request) {
  final info = request.context['shelf.io.connection_info'];
  // "is" = checagem de tipo; se for HttpConnectionInfo, usa o endereço
  return info is HttpConnectionInfo ? info.remoteAddress.address : null;
}
