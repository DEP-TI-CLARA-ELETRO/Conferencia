import 'dart:io';

import 'package:shelf/shelf.dart';

import '../core/http.dart';

/// Middleware = "filtro" que envolve TODAS as rotas.
/// Aqui: se qualquer handler explodir com exceção, devolvemos JSON 500
/// em vez de derrubar o servidor / vazar stack trace para o cliente.
Middleware errorMiddleware() {
  // Middleware em Shelf: recebe o handler interno e devolve outro handler
  return (inner) => (request) async {
        try {
          return await inner(request); // chama a rota de verdade
        } on HijackException {
          // Caso especial do Shelf (upgrade de conexão): deve subir de novo
          rethrow;
        } catch (e, st) {
          // e = erro, st = stack trace (onde quebrou)
          stderr.writeln('ERRO ${request.method} ${request.requestedUri.path}: $e\n$st');
          return jsonError(500, 'Erro interno', code: 'internal_error');
        }
      };
}
