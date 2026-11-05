import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../middleware/auth_middleware.dart';
import '../auth/auth_repository.dart';
import 'closing_detail_service.dart';
import 'closings_repository.dart';

class ClosingsRoutes {
  ClosingsRoutes(this._repo, this._authRepo, this._detail, {required this.webpostoConfigured});

  final ClosingsRepository _repo;
  final AuthRepository _authRepo;
  final ClosingDetailService _detail;
  final bool webpostoConfigured;

  Router get router {
    final r = Router();
    final pipe = const Pipeline()
        .addMiddleware(requireAuth(_authRepo))
        .addMiddleware(requirePermission(Permission.closingsView));

    r.get('/', pipe.addHandler(_list));
    r.get('/<id>/detail', pipe.addHandler(_detailOf));
    return r;
  }

  Future<Response> _detailOf(Request request) async {
    final id = request.params['id'] ?? '';
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
      return jsonError(400, 'Caixa invalido', code: 'invalid_request');
    }

    ClosingPanelSource? source;
    try {
      source = await _repo.findPanelSource(id);
    } catch (_) {
      return jsonError(400, 'Caixa invalido', code: 'invalid_request');
    }
    if (source == null) {
      return jsonError(404, 'Caixa nao encontrado', code: 'not_found');
    }
    final panel = source;

    final user = request.user;
    final isAdmin = user.roles.contains(Role.admin) || user.can(Permission.usersManage);
    if (!isAdmin && !user.stores.any((s) => s.id == panel.storeId)) {
      return jsonError(403, 'Sem acesso a esta loja', code: 'forbidden');
    }

    if (!webpostoConfigured || panel.empresaCodigo == null) {
      return jsonOk(
        const ClosingDetailDto(
          warning: 'WebPosto nao configurado. O resumo local continua disponivel.',
        ).toJson(),
      );
    }

    final detail = await _detail.load(
      caixaCodigo: panel.caixaCodigo,
      movementDate: panel.movementDate,
      empresaCodigo: panel.empresaCodigo!,
      employeeCode: panel.employeeCode,
    );
    return jsonOk(detail.toJson());
  }

  Future<Response> _list(Request request) async {
    final qp = request.url.queryParameters;

    // Aceita date (legado = 1 dia) ou dateFrom + dateTo (intervalo).
    final fromStr = qp['dateFrom'] ?? qp['date'];
    final toStr = qp['dateTo'] ?? qp['dateFrom'] ?? qp['date'];
    if (fromStr == null || fromStr.isEmpty) {
      return jsonError(
        400,
        'Informe date=yyyy-MM-dd ou dateFrom/dateTo',
        code: 'invalid_request',
      );
    }

    late DateTime from;
    late DateTime to;
    try {
      from = DateTime.parse(fromStr);
      to = DateTime.parse(toStr!);
    } catch (_) {
      return jsonError(400, 'Data invalida', code: 'invalid_request');
    }
    if (to.isBefore(from)) {
      return jsonError(400, 'dateTo deve ser >= dateFrom', code: 'invalid_request');
    }

    final storeId = int.tryParse(qp['storeId'] ?? '');
    final buRaw = qp['businessUnit']?.trim();
    final businessUnit = (buRaw == null || buRaw.isEmpty) ? null : buRaw;

    final user = request.user;
    if (storeId != null && user.stores.isNotEmpty) {
      final allowed = user.stores.any((s) => s.id == storeId);
      if (!allowed && !user.can(Permission.usersManage)) {
        return jsonError(403, 'Sem acesso a esta loja', code: 'forbidden');
      }
    }

    final list = await _repo.list(
      from: from,
      to: to,
      storeId: storeId,
      businessUnit: businessUnit,
    );

    final isAdmin = user.roles.contains(Role.admin) || user.can(Permission.usersManage);
    final storeIds = user.stores.map((s) => s.id).toSet();
    final filtered = isAdmin
        ? list
        : list.where((c) => storeIds.contains(c.storeId)).toList();

    return jsonOk({'items': filtered.map((e) => e.toJson()).toList()});
  }
}
