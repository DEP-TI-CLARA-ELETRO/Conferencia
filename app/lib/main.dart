// Ponto de entrada do app Flutter.
// É o primeiro arquivo que o Flutter executa.
// O Flutter é um framework para criar apps mobile, web e desktop com Dart.
// O Flutter é baseado em widgets (componentes visuais).
// O Flutter é reativo: quando o estado muda, a tela se redesenha automaticamente.
// O Flutter é declarativo: você descreve a tela como uma árvore de widgets, e o Flutter cuida de desenhar na tela.
// O Flutter é multiplataforma: você escreve uma vez, e roda em Android, iOS, Web, Windows, Mac e Linux.

// Dart é a linguagem de programação do Flutter.

// Importa pacotes do Flutter e de terceiros (pub.dev).
import 'package:flutter/material.dart'; // Material Design = estilo visual do Google, usado no Android e Web
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod = gerenciador de estado global (como Redux, MobX, Bloc, Provider)
import 'package:intl/date_symbol_data_local.dart'; // intl = internacionalização (datas, números, moedas, traduções)
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences = "gaveta" do navegador, para guardar dados simples (token de sessão, preferências do usuário etc.)



// Importa o arquivo app.dart, que contém o widget raiz do app.

import 'app.dart'; 

// Importa o arquivo auth_controller.dart, que contém o provider de autenticação (token de sessão).
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
