import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shared/shared.dart';

import 'webposto_client.dart';

/// Sincroniza empresas e fechamentos do WebPosto para o PostgreSQL local.
class WebpostoSyncService {
  WebpostoSyncService(this._db, this._client);

  final Pool<void> _db;
  final WebpostoClient _client;

  Future<WebpostoSyncResultDto> sync({
    required DateTime from,
    required DateTime to,
    int? empresaCodigo,
  }) async {
    final fromStr = _date(from);
    final toStr = _date(to);

    final companies = await _client.empresas();
    var companiesUpserted = 0;
    final storeByEmpresa = <int, int>{}; // empresaCodigo -> store.id

    for (final e in companies) {
      final codigo = e['empresaCodigo'] as int?;
      if (codigo == null) continue;
      if (empresaCodigo != null && codigo != empresaCodigo) continue;

      final fantasia = (e['fantasia'] as String?)?.trim();
      final razao = (e['razao'] as String?)?.trim();
      final name = (fantasia != null && fantasia.isNotEmpty)
          ? fantasia
          : (razao ?? 'Posto $codigo');
      // Prefixo WP- evita colidir com lojas manuais do seed (ex.: code "01")
      final code = 'WP-$codigo';

      final id = await _upsertStore(
        connector: 'webposto',
        externalCode: '$codigo',
        code: code,
        name: name,
        businessUnit: 'posto',
      );
      storeByEmpresa[codigo] = id;
      companiesUpserted++;
    }

    final caixas = await _client.caixas(
      dataInicial: fromStr,
      dataFinal: toStr,
      empresaCodigo: empresaCodigo,
    );
    final apresentados = await _client.caixasApresentado(
      dataInicial: fromStr,
      dataFinal: toStr,
    );

    // índice empresa+caixa -> apresentado
    final apIndex = <String, Map<String, dynamic>>{};
    for (final a in apresentados) {
      final emp = a['empresaCodigo'];
      final cx = a['caixaCodigo'];
      if (emp == null || cx == null) continue;
      apIndex['$emp|$cx'] = a;
    }

    var closingsUpserted = 0;
    for (final c in caixas) {
      final emp = c['empresaCodigo'] as int?;
      final caixaCodigo = c['caixaCodigo'] as int?;
      if (emp == null || caixaCodigo == null) continue;

      var storeId = storeByEmpresa[emp];
      storeId ??= await _ensureStoreStub(emp);
      storeByEmpresa[emp] = storeId;

      final ap = apIndex['$emp|$caixaCodigo'];
      await _upsertClosing(storeId: storeId, caixa: c, apresentado: ap);
      closingsUpserted++;
    }

    return WebpostoSyncResultDto(
      companiesUpserted: companiesUpserted,
      closingsUpserted: closingsUpserted,
      from: fromStr,
      to: toStr,
    );
  }

  Future<int> _ensureStoreStub(int empresaCodigo) => _upsertStore(
        connector: 'webposto',
        externalCode: '$empresaCodigo',
        code: 'WP-$empresaCodigo',
        name: 'Posto $empresaCodigo',
        businessUnit: 'posto',
      );

  Future<int> _upsertStore({
    required String connector,
    required String externalCode,
    required String code,
    required String name,
    required String businessUnit,
  }) async {
    final existing = await _db.execute(
      Sql.named('''
        SELECT id FROM stores
        WHERE connector = @conn AND external_code = @ext
      '''),
      parameters: {'conn': connector, 'ext': externalCode},
    );
    if (existing.isNotEmpty) {
      final id = existing.first[0] as int;
      await _db.execute(
        Sql.named('''
          UPDATE stores
          SET name = @name, business_unit = @bu, active = TRUE
          WHERE id = @id
        '''),
        parameters: {'name': name, 'bu': businessUnit, 'id': id},
      );
      return id;
    }

    final inserted = await _db.execute(
      Sql.named('''
        INSERT INTO stores (code, name, connector, external_code, business_unit)
        VALUES (@code, @name, @conn, @ext, @bu)
        ON CONFLICT (code) DO UPDATE
          SET name = EXCLUDED.name,
              connector = EXCLUDED.connector,
              external_code = EXCLUDED.external_code,
              business_unit = EXCLUDED.business_unit,
              active = TRUE
        RETURNING id
      '''),
      parameters: {
        'code': code,
        'name': name,
        'conn': connector,
        'ext': externalCode,
        'bu': businessUnit,
      },
    );
    return inserted.first[0] as int;
  }

  Future<void> _upsertClosing({
    required int storeId,
    required Map<String, dynamic> caixa,
    Map<String, dynamic>? apresentado,
  }) async {
    final movementDate = _parseDate(caixa['dataMovimento']);
    if (movementDate == null) return;

    final shiftCode = caixa['turnoCodigo'] as int?;
    final caixaCodigo = caixa['caixaCodigo'] as int;
    final breakdown = _paymentBreakdown(apresentado);
    final params = <String, Object?>{
      'store': storeId,
      'extCodigo': caixa['codigo'] as int?,
      'caixaCodigo': caixaCodigo,
      'movDate': movementDate,
      'shiftCode': shiftCode,
      'shiftLabel': caixa['turno'] as String?,
      'pdv': caixa['pdvCodigo'] as int?,
      'emp': caixa['funcionarioCodigo'] as int?,
      'opened': _parseDateTime(caixa['abertura']),
      'closedAt': _parseDateTime(caixa['fechamento']),
      'closed': caixa['fechado'] as bool? ?? false,
      'cons': caixa['consolidado'] as bool? ?? false,
      'blocked': caixa['bloqueado'] as bool? ?? false,
      'apurado': _num(caixa['apurado']),
      'diff': _num(caixa['diferenca']),
      'pay': jsonEncode(breakdown),
      'rawCaixa': jsonEncode(caixa),
      'rawAp': apresentado == null ? null : jsonEncode(apresentado),
    };

    // Busca existente (evita ON CONFLICT com expressão COALESCE no índice)
    final found = await _db.execute(
      Sql.named('''
        SELECT id FROM cash_closings
        WHERE store_id = @store
          AND connector = 'webposto'
          AND external_caixa_codigo = @caixaCodigo
          AND movement_date = @movDate
          AND COALESCE(shift_code, -1) = COALESCE(@shiftCode, -1)
      '''),
      parameters: {
        'store': storeId,
        'caixaCodigo': caixaCodigo,
        'movDate': movementDate,
        'shiftCode': shiftCode,
      },
    );

    if (found.isNotEmpty) {
      // Só variáveis usadas no UPDATE (postgres rejeita params sobrando).
      await _db.execute(
        Sql.named('''
          UPDATE cash_closings SET
            external_codigo = @extCodigo,
            shift_label = @shiftLabel,
            pdv_code = @pdv,
            employee_code = @emp,
            opened_at = @opened,
            closed_at = @closedAt,
            closed = @closed,
            consolidated = @cons,
            blocked = @blocked,
            apurado = @apurado,
            diferenca = @diff,
            payment_breakdown = @pay::jsonb,
            raw_caixa = @rawCaixa::jsonb,
            raw_apresentado = @rawAp::jsonb,
            synced_at = now(),
            updated_at = now()
          WHERE id = @id::uuid
        '''),
        parameters: {
          'id': found.first[0] as String,
          'extCodigo': params['extCodigo'],
          'shiftLabel': params['shiftLabel'],
          'pdv': params['pdv'],
          'emp': params['emp'],
          'opened': params['opened'],
          'closedAt': params['closedAt'],
          'closed': params['closed'],
          'cons': params['cons'],
          'blocked': params['blocked'],
          'apurado': params['apurado'],
          'diff': params['diff'],
          'pay': params['pay'],
          'rawCaixa': params['rawCaixa'],
          'rawAp': params['rawAp'],
        },
      );
      return;
    }

    await _db.execute(
      Sql.named('''
        INSERT INTO cash_closings (
          store_id, connector, external_codigo, external_caixa_codigo,
          movement_date, shift_code, shift_label, pdv_code, employee_code,
          opened_at, closed_at, closed, consolidated, blocked,
          apurado, diferenca, stage, payment_breakdown,
          raw_caixa, raw_apresentado, synced_at, updated_at
        ) VALUES (
          @store, 'webposto', @extCodigo, @caixaCodigo,
          @movDate, @shiftCode, @shiftLabel, @pdv, @emp,
          @opened, @closedAt, @closed, @cons, @blocked,
          @apurado, @diff, 'pdv_imported', @pay::jsonb,
          @rawCaixa::jsonb, @rawAp::jsonb, now(), now()
        )
      '''),
      parameters: params,
    );
  }

  /// Extrai pares apresentado/apurado/diferença do payload CAIXAS_APRESENTADO.
  Map<String, dynamic> _paymentBreakdown(Map<String, dynamic>? ap) {
    if (ap == null) return {};
    const forms = [
      'dinheiro',
      'notaPrazo',
      'cheque',
      'chequePre',
      'cartao',
      'cartaFrete',
      'valeCliente',
      'emprestimo',
      'prePag',
      'despesa',
      'valeFun',
      'chequePagar',
      'transfBanc',
      'transfDeb',
      'fundoCxDeb',
    ];
    final out = <String, dynamic>{};
    for (final f in forms) {
      final apresentado = _num(ap['${f}Apresentado']);
      final apurado = _num(ap['${f}Apurado']);
      final diferenca = _num(ap['${f}Diferenca']);
      if (apresentado == null && apurado == null && diferenca == null) continue;
      out[f] = {
        'apresentado': apresentado,
        'apurado': apurado,
        'diferenca': diferenca,
      };
    }
    return out;
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    final s = '$v';
    try {
      return DateTime.parse(s.length >= 10 ? s.substring(0, 10) : s);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateTime(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse('$v');
    } catch (_) {
      return null;
    }
  }

  double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
