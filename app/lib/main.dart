// Ponto de entrada do app Flutter.
// É o primeiro arquivo que o Flutter executa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/auth_controller.dart';

/// main async: precisamos esperar algumas inicializações antes de desenhar a tela.
Future<void> main() async {
  // Obrigatório antes de usar plugins (SharedPreferences etc.) com async
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega nomes de dias/meses em português (para formatLongDate)
  await initializeDateFormatting('pt_BR');

  // "Gavetinha" do navegador: vamos guardar o token de sessão nela
  final prefs = await SharedPreferences.getInstance();

  // runApp = "ligue o aplicativo com este widget raiz"
  runApp(
    // ProviderScope = liga o Riverpod (estado global) em todo o app
    ProviderScope(
      // overrides = substitui um provider pela instância real de prefs
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ConferenciaApp(),
    ),
  );
}
