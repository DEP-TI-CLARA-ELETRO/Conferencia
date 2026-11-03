import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response jsonError(int status, String message, {String? code}) => Response(
      status,
      body: jsonEncode({'error': message, 'code': ?code}),
      headers: _jsonHeaders,
    );

/// Le o corpo como JSON objeto; devolve `null` se invalido.
Future<Map<String, dynamic>?> readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

String? clientIp(Request request) {
  final info = request.context['shelf.io.connection_info'];
  return info is HttpConnectionInfo ? info.remoteAddress.address : null;
}
