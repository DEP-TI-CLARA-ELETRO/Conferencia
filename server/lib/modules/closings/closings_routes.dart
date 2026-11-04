import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../middleware/auth_middleware.dart';
import '../auth/auth_repository.dart';
import 'closings_repository.dart';

class ClosingsRoutes {
  ClosingsRoutes(this._repo, this._authRepo);

  final ClosingsRepository _repo;
  final AuthRepository _authRepo;

  Router get router {
    final r = Router();
    final pipe = const Pipeline()
        .addMiddleware(requireAuth(_authRepo))
        .addMiddleware(requirePermission(Permission.closingsView));

    r.get('/', pipe.addHandler(_list));
    return r;
  }

  Future<Response> _list(Request request) async {
    final qp = request.url.queryParameters;
    final dateStr = qp['date'];
    if (dateStr == null || dateStr.isEmpty) {
      return jsonError(400, 'Informe date=yyyy-MM-dd', code: 'invalid_request');
    }
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      return jsonError(400, 'Data invalida', code: 'invalid_request');
    }

    final storeId = int.tryParse(qp['storeId'] ?? '');
    final user = request.user;
    // Se o usuário só tem lojas específicas, não deixa pedir outra
    if (storeId != null && user.stores.isNotEmpty) {
      final allowed = user.stores.any((s) => s.id == storeId);
      if (!allowed && !user.can(Permission.usersManage)) {
        return jsonError(403, 'Sem acesso a esta loja', code: 'forbidden');
      }
    }

    final list = await _repo.list(date: date, storeId: storeId);

    // Admin vê tudo (inclui postos sincronizados depois do login).
    // Demais perfis: só lojas que já vieram no UserDto.
    final isAdmin = user.roles.contains(Role.admin) || user.can(Permission.usersManage);
    final storeIds = user.stores.map((s) => s.id).toSet();
    final filtered = isAdmin
        ? list
        : list.where((c) => storeIds.contains(c.storeId)).toList();

    return jsonOk({'items': filtered.map((e) => e.toJson()).toList()});
  }
}
