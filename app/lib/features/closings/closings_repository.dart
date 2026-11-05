import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '../../core/network/api_client.dart';

class ClosingsRepository {
  ClosingsRepository(this._api);
  final ApiClient _api;

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<ClosingDto>> list({
    required DateTime from,
    required DateTime to,
    int? storeId,
    BusinessUnit? businessUnit,
  }) async {
    try {
      final res = await _api.dio.get(
        '/closings',
        queryParameters: {
          'dateFrom': _ymd(from),
          'dateTo': _ymd(to),
          ?'storeId': storeId,
          ?'businessUnit': businessUnit?.code,
        },
      );
      final items = (res.data as Map)['items'] as List? ?? [];
      return items
          .map((e) => ClosingDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ClosingDetailDto> detail(String id) async {
    try {
      final res = await _api.dio.get(
        '/closings/$id/detail',
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      return ClosingDetailDto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<bool> webpostoConfigured() async {
    try {
      final res = await _api.dio.get('/webposto/status');
      return (res.data as Map)['configured'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<WebpostoSyncResultDto> syncWebposto({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // Sync pode varrer vários dias na API WebPosto — timeout maior.
      final res = await _api.dio.post(
        '/webposto/sync',
        data: {
          'dateFrom': _ymd(from),
          'dateTo': _ymd(to),
        },
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      return WebpostoSyncResultDto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
