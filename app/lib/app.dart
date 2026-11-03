import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_locale.dart';

/// Widget raiz: configura tema, idioma e o roteador de páginas.
///
/// ConsumerWidget = pode usar ref.watch / ref.read (Riverpod).
class ConferenciaApp extends ConsumerWidget {
  const ConferenciaApp({super.key, this.theme});

  /// Permite trocar o tema (os testes usam um tema sem Google Fonts).
  final ThemeData? theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MaterialApp.router = app Material Design usando go_router (não Navigator antigo)
    return MaterialApp.router(
      title: 'Conferência de Caixas',
      debugShowCheckedModeBanner: false, // esconde a faixa "DEBUG"
      theme: theme ?? AppTheme.light(), // se theme for null, usa o nosso tema
      routerConfig: ref.watch(routerProvider), // rotas + redirects de login
      locale: appLocale, // pt_BR
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates, // textos de calendário etc.
    );
  }
}
