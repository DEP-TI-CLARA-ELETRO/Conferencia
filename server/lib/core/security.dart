import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

/// Transforma a senha em um "hash" irreversível antes de gravar no banco.
/// Nunca guardamos a senha em texto puro.
String hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt());

/// Confere se a senha digitada bate com o hash guardado.
bool verifyPassword(String password, String hash) {
  try {
    return BCrypt.checkpw(password, hash);
  } catch (_) {
    // hash inválido / formato estranho -> trata como senha errada
    return false;
  }
}

/// Hash "falso" usado quando o e-mail NÃO existe.
/// Ideia: gastar o mesmo tempo do bcrypt para não revelar se o e-mail existe
/// (ataque de timing).
final String dummyPasswordHash = hashPassword('nao-existe-esse-usuario');

/// Gera um token de sessão aleatório e seguro (32 bytes = 256 bits).
String generateToken() {
  final rnd = Random.secure(); // gerador criptográfico
  // Lista de 32 números de 0 a 255
  final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
  // Codifica em Base64 URL-safe e remove o padding "="
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Só o HASH do token é gravado no banco.
/// Se alguém vazar a tabela sessions, ainda não tem o token original.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();
