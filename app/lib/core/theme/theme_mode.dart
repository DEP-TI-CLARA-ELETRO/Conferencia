import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

const _themeKey = 'theme_mode';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_themeKey);
    return raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref.read(sharedPreferencesProvider).setString(_themeKey, next.name);
  }
}

/// Lua no modo claro, sol no modo escuro.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key, this.foreground});

  final Color? foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      tooltip: dark ? 'Modo claro' : 'Modo escuro',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      color: foreground,
    );
  }
}
