import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';

class HealthRoutes {
  HealthRoutes(this._db);
  final Pool<void> _db;

  Router get router {
    final r = Router();
    r.get('/', (Request request) async {
      try {
        await _db.execute('SELECT 1');
        return jsonOk({'status': 'ok', 'db': 'up'});
      } catch (_) {
        return jsonError(503, 'Banco indisponivel', code: 'db_down');
      }
    });
    return r;
  }
}
