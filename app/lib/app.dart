import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode.dart';
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
    final mode = theme == null ? ref.watch(themeModeProvider) : ThemeMode.light;
    return MaterialApp.router(
      title: 'Conferência de Caixas',
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.light(),
      darkTheme: theme ?? AppTheme.dark(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      locale: appLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        AppColors.bind(dark);
        return PaletteScope(dark: dark, child: child ?? const SizedBox.shrink());
      },
    );
  }
}
