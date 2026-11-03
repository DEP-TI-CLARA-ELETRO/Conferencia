import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/config.dart';
import 'middleware/error_middleware.dart';
import 'modules/auth/auth_repository.dart';
import 'modules/auth/auth_routes.dart';
import 'modules/health/health_routes.dart';

Handler buildHandler(AppConfig config, Pool<void> db, AuthRepository authRepo) {
  final root = Router()
    ..mount('/health', HealthRoutes(db).router.call)
    ..mount('/auth', AuthRoutes(authRepo, config).router.call);

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
