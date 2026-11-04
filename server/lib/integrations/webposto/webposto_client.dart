import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP da API WebPosto (Quality).
/// Autenticação: query `chave=<token>` em todas as chamadas.
class WebpostoClient {
  WebpostoClient({
    required this.baseUrl,
    required this.chave,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String chave;
  final http.Client _http;

  static const _pageSize = 500;

  /// GET genérico com paginação por ultimoCodigo.
  Future<List<Map<String, dynamic>>> fetchAll(
    String path, {
    Map<String, String>? query,
  }) async {
    final all = <Map<String, dynamic>>[];
    int? ultimoCodigo;

    while (true) {
      final params = <String, String>{
        'chave': chave,
        'limite': '$_pageSize',
        ...?query,
      };
      if (ultimoCodigo != null) params['ultimoCodigo'] = '$ultimoCodigo';

      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
      final res = await _http.get(uri, headers: {'accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw WebpostoException(
          'WebPosto $path falhou (${res.statusCode}): ${res.body}',
          statusCode: res.statusCode,
        );
      }

      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        throw WebpostoException('Resposta inesperada em $path');
      }

      final resultados = body['resultados'];
      if (resultados is! List || resultados.isEmpty) break;

      for (final item in resultados) {
        if (item is Map<String, dynamic>) all.add(item);
      }

      final next = body['ultimoCodigo'];
      if (next == null || resultados.length < _pageSize) break;
      ultimoCodigo = next is int ? next : int.tryParse('$next');
      if (ultimoCodigo == null) break;
    }

    return all;
  }

  Future<List<Map<String, dynamic>>> empresas() =>
      fetchAll('/INTEGRACAO/V1/EMPRESAS');

  Future<List<Map<String, dynamic>>> caixas({
    required String dataInicial,
    required String dataFinal,
    int? empresaCodigo,
  }) {
    final q = <String, String>{
      'dataInicial': dataInicial,
      'dataFinal': dataFinal,
    };
    if (empresaCodigo != null) q['empresaCodigo'] = '$empresaCodigo';
    return fetchAll('/INTEGRACAO/V1/CAIXAS', query: q);
  }

  Future<List<Map<String, dynamic>>> caixasApresentado({
    required String dataInicial,
    required String dataFinal,
  }) =>
      fetchAll('/INTEGRACAO/V1/CAIXAS_APRESENTADO', query: {
        'dataInicial': dataInicial,
        'dataFinal': dataFinal,
        'tipoData': 'EMISSAO',
      });

  void close() => _http.close();
}

class WebpostoException implements Exception {
  WebpostoException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
