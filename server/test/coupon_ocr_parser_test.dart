import 'package:server/modules/closings/coupon_ocr_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = CouponOcrParser();

  test('extrai dinheiro e cartao de um cupom tipico', () {
    const text = '''
FECHAMENTO DE CAIXA
DINHEIRO ........ R\$ 1.634,38
CARTAO .......... R\$ 1.494,83
NOTAS A PRAZO ... R\$ 7.876,24
''';
    final parsed = parser.parse(text);
    expect(parsed['dinheiro'], closeTo(1634.38, 0.001));
    expect(parsed['cartao'], closeTo(1494.83, 0.001));
    expect(parsed['notaPrazo'], closeTo(7876.24, 0.001));
  });
}
