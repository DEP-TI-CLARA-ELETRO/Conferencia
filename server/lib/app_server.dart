import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/config.dart';
import 'middleware/error_middleware.dart';
import 'modules/auth/auth_repository.dart';
import 'modules/auth/auth_routes.dart';
import 'modules/health/health_routes.dart';

/// Monta o "handler" raiz da API: middlewares + rotas.
Handler buildHandler(AppConfig config, Pool<void> db, AuthRepository authRepo) {
  // Router principal: encaixa sub-rotas sob um prefixo
  final root = Router()
    ..mount('/health', HealthRoutes(db).router.call) // GET /health
    ..mount('/auth', AuthRoutes(authRepo, config).router.call); // /auth/*

  // Pipeline: ordem de fora para dentro
  // 1) captura erros
  // 2) loga cada request no console
  // 3) CORS (permite o Flutter Web chamar a API de outra origem/porta)
  // 4) finalmente o router
  return const Pipeline()
      .addMiddleware(errorMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
        ACCESS_CONTROL_ALLOW_ORIGIN: config.corsOrigin,
        ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
        ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      }))
      .addHandler(root.call);
}
