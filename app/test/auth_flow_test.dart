import 'dart:convert';
import 'dart:typed_data';

import 'package:conferencia_app/app.dart';
import 'package:conferencia_app/core/network/api_client.dart';
import 'package:conferencia_app/features/auth/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API falsa: usuarios por e-mail; token = "tok-" + e-mail.
class FakeApiAdapter implements HttpClientAdapter {
  static const users = {
    'fiscal@x.com': ['fiscal', ['home.view', 'closings.view', 'closings.fiscal']],
    'rh@x.com': ['rh', ['home.view', 'hr.view']],
  };

  Map<String, dynamic> _user(String email) {
    final u = users[email]!;
    return {
      'id': 'id-$email',
      'email': email,
      'name': 'Maria Silva',
      'roles': [u[0]],
      'permissions': u[1],
      'stores': [
        {'id': 1, 'code': '01', 'name': 'Loja 01 - Centro'},
      ],
    };
  }

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/login') {
      final data = options.data as Map;
      final email = data['email'] as String;
      if (!users.containsKey(email) || data['password'] != 'senha') {
        return _json({'error': 'E-mail ou senha invalidos', 'code': 'invalid_credentials'}, 401);
      }
      return _json({
        'token': 'tok-$email',
        'expiresAt': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
        'user': _user(email),
      }, 200);
    }

    final auth = options.headers['authorization'] as String?;
    final email = auth?.replaceFirst('Bearer tok-', '');
    if (email == null || !users.containsKey(email)) {
      return _json({'error': 'Sessao invalida ou expirada', 'code': 'session_expired'}, 401);
    }
    if (options.path == '/auth/me') return _json(_user(email), 200);
    if (options.path == '/auth/logout') return _json({'ok': true}, 200);
    return _json({'error': 'not found'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

Future<SharedPreferences> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

Future<void> _pumpApp(WidgetTester tester, SharedPreferences prefs) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = ApiClient(baseUrl: 'http://fake')..dio.httpClientAdapter = FakeApiAdapter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(api),
      ],
      child: ConferenciaApp(theme: ThemeData(useMaterial3: true)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('sem sessao mostra o login', (tester) async {
    await _pumpApp(tester, await _prefs());
    expect(find.text('Conferência de Caixas'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('senha errada mostra erro e permanece no login', (tester) async {
    await _pumpApp(tester, await _prefs());
    await _login(tester, 'fiscal@x.com', 'errada');
    expect(find.text('E-mail ou senha invalidos'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('fiscal entra e ve Inicio e Caixas do dia; sair volta ao login', (tester) async {
    final prefs = await _prefs();
    await _pumpApp(tester, prefs);
    await _login(tester, 'fiscal@x.com', 'senha');

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Caixas do dia'), findsOneWidget);
    expect(find.text('Loja 01 - Centro'), findsOneWidget);
    expect(prefs.getString('session_token'), 'tok-fiscal@x.com');

    await tester.tap(find.text('Caixas do dia'));
    await tester.pumpAndSettle();
    expect(find.text('Caixa 101'), findsOneWidget);

    // menu do usuario -> Sair
    await tester.tap(find.text('MS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(prefs.getString('session_token'), isNull);
  });

  testWidgets('perfil sem closings.view nao ve o menu nem acessa /caixas', (tester) async {
    await _pumpApp(tester, await _prefs());
    await _login(tester, 'rh@x.com', 'senha');

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Caixas do dia'), findsNothing);
  });

  testWidgets('sessao salva e valida e restaurada ao abrir o app', (tester) async {
    await _pumpApp(tester, await _prefs({'session_token': 'tok-fiscal@x.com'}));
    expect(find.text('Caixas do dia'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('sessao salva e expirada leva ao login e limpa o token', (tester) async {
    final prefs = await _prefs({'session_token': 'tok-expirado@x.com'});
    await _pumpApp(tester, prefs);
    expect(find.text('Entrar'), findsOneWidget);
    expect(prefs.getString('session_token'), isNull);
  });
}
