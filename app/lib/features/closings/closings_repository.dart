import 'package:shared/shared.dart';

import '../../core/network/api_client.dart';

class ClosingsRepository {
  ClosingsRepository(this._api);
  final ApiClient _api;

  Future<List<ClosingDto>> list({required DateTime date, int? storeId}) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final res = await _api.dio.get(
        '/closings',
        queryParameters: {
          'date': day,
          'storeId': ?storeId,
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

  Future<bool> webpostoConfigured() async {
    try {
      final res = await _api.dio.get('/webposto/status');
      return (res.data as Map)['configured'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<WebpostoSyncResultDto> syncWebposto({required DateTime date}) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final res = await _api.dio.post('/webposto/sync', data: {'date': day});
      return WebpostoSyncResultDto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
