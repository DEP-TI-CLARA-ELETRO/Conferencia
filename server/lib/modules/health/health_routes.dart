import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';

/// Rota de "batimento cardíaco": GET /health
/// Serve para saber se a API e o banco estão no ar (monitoramento / smoke test).
class HealthRoutes {
  HealthRoutes(this._db);
  final Pool<void> _db;

  Router get router {
    final r = Router();
    r.get('/', (Request request) async {
      try {
        await _db.execute('SELECT 1'); // consulta mínima no Postgres
        return jsonOk({'status': 'ok', 'db': 'up'});
      } catch (_) {
        // Banco fora = 503 Service Unavailable
        return jsonError(503, 'Banco indisponivel', code: 'db_down');
      }
    });
    return r;
  }
}
