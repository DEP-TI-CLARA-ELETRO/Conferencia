import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/config.dart';
import 'integrations/webposto/webposto_client.dart';
import 'integrations/webposto/webposto_sync_service.dart';
import 'middleware/error_middleware.dart';
import 'modules/auth/auth_repository.dart';
import 'modules/auth/auth_routes.dart';
import 'modules/closings/closing_detail_service.dart';
import 'modules/closings/closings_repository.dart';
import 'modules/closings/closings_routes.dart';
import 'modules/health/health_routes.dart';
import 'modules/webposto/webposto_routes.dart';

/// Monta o handler raiz da API: middlewares + rotas.
Handler buildHandler(AppConfig config, Pool<void> db, AuthRepository authRepo) {
  final webpostoClient = WebpostoClient(
    baseUrl: config.webpostoBaseUrl,
    chave: config.webpostoChave,
  );
  final webpostoSync = WebpostoSyncService(db, webpostoClient);
  final closingsRepo = ClosingsRepository(db);
  final closingDetail = ClosingDetailService(webpostoClient);

  final root = Router()
    ..mount('/health', HealthRoutes(db).router.call)
    ..mount('/auth', AuthRoutes(authRepo, config).router.call)
    ..mount(
      '/closings',
      ClosingsRoutes(
        closingsRepo,
        authRepo,
        closingDetail,
        webpostoConfigured: config.webpostoConfigured,
      ).router.call,
    )
    ..mount('/webposto', WebpostoRoutes(config, authRepo, webpostoSync).router.call);

  return Pipeline()
      .addMiddleware(errorMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
        ACCESS_CONTROL_ALLOW_ORIGIN: config.corsOrigin,
        ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
        ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      }))
      .addHandler(root.call);
}
