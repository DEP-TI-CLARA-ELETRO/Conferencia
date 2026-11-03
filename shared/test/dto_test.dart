import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  test('SessionDto faz round-trip em JSON', () {
    final s = SessionDto(
      token: 'abc',
      expiresAt: DateTime.utc(2026, 1, 1),
      user: const UserDto(
        id: 'u1',
        email: 'a@b.c',
        name: 'Maria Silva',
        roles: [Role.fiscal],
        permissions: {Permission.homeView, Permission.closingsView},
        stores: [StoreDto(id: 1, code: '01', name: 'Loja 01')],
      ),
    );
    final back = SessionDto.fromJson(s.toJson());
    expect(back.user.initials, 'MS');
    expect(back.user.can(Permission.closingsView), isTrue);
    expect(back.user.can(Permission.usersManage), isFalse);
    expect(back.user.roles.single, Role.fiscal);
  });
}
