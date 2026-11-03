import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_locale.dart';

class ConferenciaApp extends ConsumerWidget {
  const ConferenciaApp({super.key, this.theme});

  /// Permite trocar o tema (os testes usam um tema sem Google Fonts).
  final ThemeData? theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Conferência de Caixas',
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      locale: appLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
    );
  }
}
