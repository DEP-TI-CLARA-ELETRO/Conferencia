import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'coupon_ocr_parser.dart';

class OcrEngineResult {
  const OcrEngineResult({
    required this.engine,
    this.rawText,
    this.parsed = const {},
    this.confidence,
    this.error,
  });

  final String engine;
  final String? rawText;
  final Map<String, double> parsed;
  final double? confidence;
  final String? error;
}

class CouponOcrFusion {
  const CouponOcrFusion({
    required this.runs,
    required this.proposed,
    this.warning,
  });

  final List<OcrEngineResult> runs;
  final Map<String, double> proposed;
  final String? warning;
}

/// Dois motores: Google Cloud Vision (API key) + Tesseract CLI.
class CouponOcrService {
  CouponOcrService({
    this.visionApiKey = '',
    this.tesseractBin = 'tesseract',
    http.Client? httpClient,
    CouponOcrParser? parser,
  })  : _http = httpClient ?? http.Client(),
        _parser = parser ?? CouponOcrParser();

  final String visionApiKey;
  final String tesseractBin;
  final http.Client _http;
  final CouponOcrParser _parser;

  bool get visionConfigured => visionApiKey.trim().isNotEmpty;

  Future<CouponOcrFusion> runBoth({
    required Uint8List bytes,
    required String imagePath,
  }) async {
    final visionFuture = _runVision(bytes);
    final tessFuture = _runTesseract(imagePath);
    final vision = await visionFuture;
    final tess = await tessFuture;
    final runs = [vision, tess];
    final fused = _fuse(vision, tess);
    final warnings = <String>[];
    if (vision.error != null) warnings.add('Vision: ${vision.error}');
    if (tess.error != null) warnings.add('Tesseract: ${tess.error}');
    if (fused.divergingKeys.isNotEmpty) {
      warnings.add(
        'Motores divergem em: ${fused.divergingKeys.join(', ')}. Revise os campos destacados.',
      );
    }
    if (fused.values.isEmpty) {
      warnings.add('Nenhum valor de pagamento identificado no cupom.');
    }
    return CouponOcrFusion(
      runs: runs,
      proposed: fused.values,
      warning: warnings.isEmpty ? null : warnings.join(' | '),
    );
  }

  ({Map<String, double> values, List<String> divergingKeys}) _fuse(
    OcrEngineResult a,
    OcrEngineResult b,
  ) {
    final keys = {...a.parsed.keys, ...b.parsed.keys};
    final out = <String, double>{};
    final diverging = <String>[];
    for (final k in keys) {
      final va = a.parsed[k];
      final vb = b.parsed[k];
      if (va != null && vb != null) {
        if ((va - vb).abs() < 0.015) {
          out[k] = _round2(va);
        } else {
          out[k] = _round2((va + vb) / 2);
          diverging.add(k);
        }
      } else {
        out[k] = _round2(va ?? vb!);
      }
    }
    return (values: out, divergingKeys: diverging);
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100;

  Future<OcrEngineResult> _runVision(Uint8List bytes) async {
    if (!visionConfigured) {
      return const OcrEngineResult(
        engine: 'vision',
        error: 'GOOGLE_VISION_API_KEY nao configurada',
      );
    }
    try {
      final uri = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=${visionApiKey.trim()}',
      );
      final body = {
        'requests': [
          {
            'image': {'content': base64Encode(bytes)},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
          },
        ],
      };
      final res = await _http
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode >= 300) {
        return OcrEngineResult(
          engine: 'vision',
          error: 'HTTP ${res.statusCode}',
        );
      }
      final decoded = jsonDecode(res.body);
      final responses = decoded is Map ? decoded['responses'] as List? : null;
      final first = responses != null && responses.isNotEmpty ? responses.first : null;
      String? text;
      if (first is Map) {
        final full = first['fullTextAnnotation'];
        if (full is Map && full['text'] is String) {
          text = full['text'] as String;
        } else {
          final ann = first['textAnnotations'];
          if (ann is List && ann.isNotEmpty && ann.first is Map) {
            text = (ann.first as Map)['description'] as String?;
          }
        }
        if (first['error'] is Map) {
          return OcrEngineResult(
            engine: 'vision',
            error: '${(first['error'] as Map)['message']}',
          );
        }
      }
      text ??= '';
      final parsed = _parser.parse(text);
      return OcrEngineResult(
        engine: 'vision',
        rawText: text,
        parsed: parsed,
        confidence: parsed.isEmpty ? 0.2 : 0.85,
      );
    } catch (e) {
      return OcrEngineResult(engine: 'vision', error: e.toString());
    }
  }

  Future<OcrEngineResult> _runTesseract(String imagePath) async {
    try {
      final result = await Process.run(
        tesseractBin,
        [imagePath, 'stdout', '-l', 'por+eng', '--psm', '6'],
        runInShell: Platform.isWindows,
      ).timeout(const Duration(seconds: 60));
      if (result.exitCode != 0) {
        final err = '${result.stderr}'.trim();
        return OcrEngineResult(
          engine: 'tesseract',
          error: err.isEmpty ? 'exit ${result.exitCode}' : err,
        );
      }
      final text = '${result.stdout}';
      final parsed = _parser.parse(text);
      return OcrEngineResult(
        engine: 'tesseract',
        rawText: text,
        parsed: parsed,
        confidence: parsed.isEmpty ? 0.15 : 0.65,
      );
    } on ProcessException catch (e) {
      return OcrEngineResult(
        engine: 'tesseract',
        error: 'Tesseract indisponivel (${e.message})',
      );
    } catch (e) {
      return OcrEngineResult(engine: 'tesseract', error: e.toString());
    }
  }
}
