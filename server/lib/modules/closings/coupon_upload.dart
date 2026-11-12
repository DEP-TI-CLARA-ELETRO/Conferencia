import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import '../../core/http.dart';

class UploadedCouponImage {
  const UploadedCouponImage({
    required this.bytes,
    this.filename,
    this.contentType,
  });

  final Uint8List bytes;
  final String? filename;
  final String? contentType;
}

/// Aceita multipart (campo `file`) ou JSON `{ imageBase64, filename, contentType }`.
Future<UploadedCouponImage?> readCouponImage(Request request) async {
  final ct = request.headers['content-type'] ?? '';
  if (ct.toLowerCase().contains('multipart/form-data')) {
    return _readMultipart(request, ct);
  }
  final body = await readJson(request);
  if (body == null) return null;
  final b64 = body['imageBase64'] as String?;
  if (b64 == null || b64.isEmpty) return null;
  final cleaned = b64.contains(',') ? b64.split(',').last : b64;
  try {
    return UploadedCouponImage(
      bytes: base64Decode(cleaned),
      filename: body['filename'] as String? ?? 'cupom.jpg',
      contentType: body['contentType'] as String? ?? 'image/jpeg',
    );
  } catch (_) {
    return null;
  }
}

Future<UploadedCouponImage?> _readMultipart(Request request, String contentType) async {
  final boundaryMatch = RegExp(r'boundary=(?:"([^"]+)"|([^;]+))', caseSensitive: false)
      .firstMatch(contentType);
  if (boundaryMatch == null) return null;
  final boundary = (boundaryMatch.group(1) ?? boundaryMatch.group(2))!.trim();
  final raw = await request.read().fold<List<int>>(
    <int>[],
    (prev, chunk) => prev..addAll(chunk),
  );
  final bytes = Uint8List.fromList(raw);
  final separator = utf8.encode('--$boundary');
  var start = _indexOf(bytes, separator, 0);
  if (start < 0) return null;
  start += separator.length;
  if (start + 1 < bytes.length && bytes[start] == 13 && bytes[start + 1] == 10) {
    start += 2;
  }

  while (start < bytes.length) {
    if (bytes[start] == 45 && start + 1 < bytes.length && bytes[start + 1] == 45) {
      break; // --
    }
    final next = _indexOf(bytes, separator, start);
    final end = next < 0 ? bytes.length : next;
    var part = bytes.sublist(start, end);
    // trim trailing CRLF before boundary
    while (part.length >= 2 && part[part.length - 2] == 13 && part[part.length - 1] == 10) {
      part = part.sublist(0, part.length - 2);
    }
    final headerEnd = _indexOf(part, utf8.encode('\r\n\r\n'), 0);
    if (headerEnd >= 0) {
      final headers = utf8.decode(part.sublist(0, headerEnd), allowMalformed: true);
      final body = part.sublist(headerEnd + 4);
      final name = RegExp(r'name="([^"]+)"').firstMatch(headers)?.group(1);
      if (name == 'file' || name == 'image') {
        final filename = RegExp(r'filename="([^"]*)"').firstMatch(headers)?.group(1);
        final partCt = RegExp(r'content-type:\s*([^\r\n]+)', caseSensitive: false)
            .firstMatch(headers)
            ?.group(1)
            ?.trim();
        return UploadedCouponImage(
          bytes: Uint8List.fromList(body),
          filename: (filename == null || filename.isEmpty) ? 'cupom.jpg' : filename,
          contentType: partCt ?? 'application/octet-stream',
        );
      }
    }
    if (next < 0) break;
    start = next + separator.length;
    if (start + 1 < bytes.length && bytes[start] == 13 && bytes[start + 1] == 10) {
      start += 2;
    }
  }
  return null;
}

int _indexOf(Uint8List data, List<int> pattern, int from) {
  if (pattern.isEmpty || from >= data.length) return -1;
  outer:
  for (var i = from; i <= data.length - pattern.length; i++) {
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) continue outer;
    }
    return i;
  }
  return -1;
}
