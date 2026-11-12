import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http.dart';
import '../../middleware/auth_middleware.dart';
import '../auth/auth_repository.dart';
import 'coupon_match_service.dart';
import 'coupon_ocr_service.dart';
import 'coupon_upload.dart';
import 'coupons_repository.dart';

class CouponsRoutes {
  CouponsRoutes(
    this._repo,
    this._authRepo,
    this._ocr,
    this._match, {
    required this.uploadsDir,
  });

  final CouponsRepository _repo;
  final AuthRepository _authRepo;
  final CouponOcrService _ocr;
  final CouponMatchService _match;
  final String uploadsDir;

  static final _uuid = RegExp(r'^[0-9a-fA-F-]{36}$');

  Router get router {
    final r = Router();
    final pipe = const Pipeline()
        .addMiddleware(requireAuth(_authRepo))
        .addMiddleware(requirePermission(Permission.closingsView));

    r.get('/<closingId>/coupons', pipe.addHandler(_list));
    r.post('/<closingId>/coupons', pipe.addHandler(_upload));
    r.get('/<closingId>/coupons/<couponId>/image', pipe.addHandler(_image));
    r.post('/<closingId>/coupons/<couponId>/confirm', pipe.addHandler(_confirm));
    return r;
  }

  Future<Response> _list(Request request) async {
    final closingId = request.params['closingId'] ?? '';
    if (!_uuid.hasMatch(closingId)) {
      return jsonError(400, 'Caixa invalido', code: 'invalid_request');
    }
    final closing = await _repo.findClosing(closingId);
    if (closing == null) {
      return jsonError(404, 'Caixa nao encontrado', code: 'not_found');
    }
    final denied = _denyStore(request, closing.storeId);
    if (denied != null) return denied;

    final items = await _repo.listByClosing(closingId);
    return jsonOk({'items': items.map((e) => e.toJson()).toList()});
  }

  Future<Response> _upload(Request request) async {
    final closingId = request.params['closingId'] ?? '';
    if (!_uuid.hasMatch(closingId)) {
      return jsonError(400, 'Caixa invalido', code: 'invalid_request');
    }
    final closing = await _repo.findClosing(closingId);
    if (closing == null) {
      return jsonError(404, 'Caixa nao encontrado', code: 'not_found');
    }
    final denied = _denyStore(request, closing.storeId);
    if (denied != null) return denied;

    final uploaded = await readCouponImage(request);
    if (uploaded == null || uploaded.bytes.isEmpty) {
      return jsonError(
        400,
        'Envie a imagem (multipart file ou JSON imageBase64)',
        code: 'invalid_request',
      );
    }
    if (uploaded.bytes.length > 12 * 1024 * 1024) {
      return jsonError(400, 'Imagem muito grande (max 12MB)', code: 'invalid_request');
    }

    final dir = Directory(p.join(uploadsDir, closingId));
    await dir.create(recursive: true);
    final ext = _extFor(uploaded.filename, uploaded.contentType);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final absolute = p.join(dir.path, fileName);
    await File(absolute).writeAsBytes(uploaded.bytes, flush: true);

    final relative = p.join(closingId, fileName).replaceAll('\\', '/');
    final user = request.user;
    var coupon = await _repo.insertUploaded(
      closingId: closingId,
      storagePath: relative,
      originalFilename: uploaded.filename,
      contentType: uploaded.contentType,
      createdBy: user.id,
    );

    final fusion = await _ocr.runBoth(bytes: uploaded.bytes, imagePath: absolute);
    final status = fusion.proposed.isEmpty &&
            fusion.runs.every((r) => r.error != null)
        ? 'failed'
        : 'ocr_ready';

    await _repo.saveOcrResult(
      couponId: coupon.id,
      status: status,
      proposed: fusion.proposed,
      warning: fusion.warning,
      runs: [
        for (final run in fusion.runs)
          OcrRunInsert(
            engine: run.engine,
            rawText: run.rawText,
            parsed: run.parsed,
            confidence: run.confidence,
            error: run.error,
          ),
      ],
    );

    coupon = (await _repo.findCoupon(coupon.id))!;
    return jsonOk(coupon.toJson(), status: 201);
  }

  Future<Response> _image(Request request) async {
    final closingId = request.params['closingId'] ?? '';
    final couponId = request.params['couponId'] ?? '';
    if (!_uuid.hasMatch(closingId) || !_uuid.hasMatch(couponId)) {
      return jsonError(400, 'Identificador invalido', code: 'invalid_request');
    }
    final closing = await _repo.findClosing(closingId);
    if (closing == null) {
      return jsonError(404, 'Caixa nao encontrado', code: 'not_found');
    }
    final denied = _denyStore(request, closing.storeId);
    if (denied != null) return denied;

    final coupon = await _repo.findCoupon(couponId);
    if (coupon == null || coupon.closingId != closingId) {
      return jsonError(404, 'Cupom nao encontrado', code: 'not_found');
    }
    final relative = await _repo.storagePathOf(couponId);
    if (relative == null) {
      return jsonError(404, 'Arquivo nao encontrado', code: 'not_found');
    }
    final file = File(p.join(uploadsDir, relative));
    if (!file.existsSync()) {
      return jsonError(404, 'Arquivo nao encontrado', code: 'not_found');
    }
    final bytes = await file.readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'content-type': coupon.contentType ?? 'image/jpeg',
        'cache-control': 'private, max-age=120',
      },
    );
  }

  Future<Response> _confirm(Request request) async {
    final closingId = request.params['closingId'] ?? '';
    final couponId = request.params['couponId'] ?? '';
    if (!_uuid.hasMatch(closingId) || !_uuid.hasMatch(couponId)) {
      return jsonError(400, 'Identificador invalido', code: 'invalid_request');
    }
    final closing = await _repo.findClosing(closingId);
    if (closing == null) {
      return jsonError(404, 'Caixa nao encontrado', code: 'not_found');
    }
    final denied = _denyStore(request, closing.storeId);
    if (denied != null) return denied;

    final coupon = await _repo.findCoupon(couponId);
    if (coupon == null || coupon.closingId != closingId) {
      return jsonError(404, 'Cupom nao encontrado', code: 'not_found');
    }

    final body = await readJson(request) ?? {};
    final rawValues = body['values'];
    Map<String, double> values;
    if (rawValues is Map) {
      values = {};
      for (final e in rawValues.entries) {
        final v = e.value;
        if (v is num) values['${e.key}'] = v.toDouble();
        if (v is String) {
          final n = double.tryParse(v.replaceAll('.', '').replaceAll(',', '.')) ??
              double.tryParse(v.replaceAll(',', '.'));
          if (n != null) values['${e.key}'] = n;
        }
      }
    } else {
      values = Map<String, double>.from(coupon.proposedValues.amounts);
    }
    if (values.isEmpty) {
      return jsonError(400, 'Informe os valores confirmados', code: 'invalid_request');
    }

    final match = _match.match(
      paymentBreakdown: closing.paymentBreakdown,
      scanned: values,
      closingApurado: closing.apurado,
    );

    final updated = await _repo.confirm(
      couponId: couponId,
      values: values,
      match: match,
      confirmedBy: request.user.id,
    );
    return jsonOk(updated.toJson());
  }

  Response? _denyStore(Request request, int storeId) {
    final user = request.user;
    final isAdmin = user.roles.contains(Role.admin) || user.can(Permission.usersManage);
    if (!isAdmin && !user.stores.any((s) => s.id == storeId)) {
      return jsonError(403, 'Sem acesso a esta loja', code: 'forbidden');
    }
    return null;
  }

  String _extFor(String? filename, String? contentType) {
    final lower = (filename ?? '').toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('png')) return '.png';
    if (ct.contains('webp')) return '.webp';
    return '.jpg';
  }
}
