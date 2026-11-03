import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

String hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt());

bool verifyPassword(String password, String hash) {
  try {
    return BCrypt.checkpw(password, hash);
  } catch (_) {
    return false;
  }
}

/// Hash fixo usado para gastar o mesmo tempo quando o e-mail nao existe.
final String dummyPasswordHash = hashPassword('nao-existe-esse-usuario');

/// Token opaco de sessao (256 bits).
String generateToken() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// So o hash do token e gravado no banco.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();
