import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../config/config.dart';
import '../../core/http.dart';
import '../../integrations/webposto/webposto_client.dart';
import '../../integrations/webposto/webposto_sync_service.dart';
import '../../middleware/auth_middleware.dart';
import '../auth/auth_repository.dart';

class WebpostoRoutes {
  WebpostoRoutes(this._config, this._authRepo, this._sync);

  final AppConfig _config;
  final AuthRepository _authRepo;
  final WebpostoSyncService _sync;

  Router get router {
    final r = Router();
    final pipe = const Pipeline()
        .addMiddleware(requireAuth(_authRepo))
        .addMiddleware(requirePermission(Permission.closingsView, Permission.usersManage));

    r.get('/status', pipe.addHandler(_status));
    r.post('/sync', pipe.addHandler(_syncHandler));
    return r;
  }

  Future<Response> _status(Request request) async {
    return jsonOk({
      'configured': _config.webpostoConfigured,
      'baseUrl': _config.webpostoBaseUrl,
    });
  }

  Future<Response> _syncHandler(Request request) async {
    if (!_config.webpostoConfigured) {
      return jsonError(
        503,
        'WEBPOSTO_CHAVE nao configurada no server/.env',
        code: 'webposto_not_configured',
      );
    }

    final body = await readJson(request) ?? {};
    final dateStr = body['date'] as String? ??
        request.url.queryParameters['date'];
    final fromStr = body['dateFrom'] as String? ?? dateStr;
    final toStr = body['dateTo'] as String? ?? fromStr;
    late DateTime from;
    late DateTime to;
    try {
      final now = DateTime.now();
      final parsedFrom = fromStr != null && fromStr.isNotEmpty
          ? DateTime.parse(fromStr)
          : now;
      final parsedTo = toStr != null && toStr.isNotEmpty
          ? DateTime.parse(toStr)
          : parsedFrom;
      from = DateTime(parsedFrom.year, parsedFrom.month, parsedFrom.day);
      to = DateTime(parsedTo.year, parsedTo.month, parsedTo.day);
    } catch (_) {
      return jsonError(400, 'Data invalida', code: 'invalid_request');
    }
    if (to.isBefore(from)) {
      return jsonError(400, 'dateTo deve ser >= dateFrom', code: 'invalid_request');
    }
    final empresaCodigo = body['empresaCodigo'] as int? ??
        int.tryParse('${body['empresaCodigo'] ?? ''}');

    try {
      final result = await _sync.sync(
        from: from,
        to: to,
        empresaCodigo: empresaCodigo,
      );
      return jsonOk(result.toJson());
    } on WebpostoException catch (e) {
      return jsonError(502, e.message, code: 'webposto_error');
    }
  }
}
