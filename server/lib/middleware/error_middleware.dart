import 'dart:io';

import 'package:shelf/shelf.dart';

import '../core/http.dart';

/// Captura erros nao tratados e devolve JSON 500 sem vazar detalhes.
Middleware errorMiddleware() {
  return (inner) => (request) async {
        try {
          return await inner(request);
        } on HijackException {
          rethrow;
        } catch (e, st) {
          stderr.writeln('ERRO ${request.method} ${request.requestedUri.path}: $e\n$st');
          return jsonError(500, 'Erro interno', code: 'internal_error');
        }
      };
}
