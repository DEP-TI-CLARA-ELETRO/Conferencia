import 'package:server/core/security.dart';
import 'package:test/test.dart';

void main() {
  test('hash e verificacao de senha', () {
    final h = hashPassword('segredo');
    expect(verifyPassword('segredo', h), isTrue);
    expect(verifyPassword('outra', h), isFalse);
    expect(verifyPassword('x', 'hash-invalido'), isFalse);
  });

  test('tokens sao unicos e o hash e estavel', () {
    final a = generateToken();
    final b = generateToken();
    expect(a, isNot(b));
    expect(a.length, greaterThanOrEqualTo(40));
    expect(hashToken(a), hashToken(a));
    expect(hashToken(a), isNot(a));
  });
}
