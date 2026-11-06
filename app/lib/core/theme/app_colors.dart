import 'package:flutter/material.dart';

/// Paleta concreta. Claro e escuro existem ao mesmo tempo no ThemeData.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.backgroundTint,
    required this.surface,
    required this.surfaceMuted,
    required this.panel,
    required this.border,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.primaryMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.neutralSoft,
    required this.sidebar,
    required this.sidebarEnd,
    required this.sidebarMuted,
    required this.sidebarText,
    required this.sidebarTextActive,
    required this.shadow,
  });

  final Color background;
  final Color backgroundTint;
  final Color surface;
  final Color surfaceMuted;
  final Color panel;
  final Color border;
  final Color divider;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color primaryMuted;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color neutralSoft;
  final Color sidebar;
  final Color sidebarEnd;
  final Color sidebarMuted;
  final Color sidebarText;
  final Color sidebarTextActive;
  final Color shadow;

  static const light = AppPalette(
    background: Color(0xFFF3F5F8),
    backgroundTint: Color(0xFFE8EEF3),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF8FAFC),
    panel: Color(0xFFFBFBFD),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFEEF2F6),
    text: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    primary: Color(0xFF1D4ED8),
    primaryHover: Color(0xFF2563EB),
    primarySoft: Color(0xFFDBEAFE),
    primaryMuted: Color(0xFFEFF6FF),
    success: Color(0xFF047857),
    successSoft: Color(0xFFD1FAE5),
    warning: Color(0xFFB45309),
    warningSoft: Color(0xFFFEF3C7),
    danger: Color(0xFFBE123C),
    dangerSoft: Color(0xFFFFE4E6),
    neutralSoft: Color(0xFFF1F5F9),
    sidebar: Color(0xFF0E1C36),
    sidebarEnd: Color(0xFF163056),
    sidebarMuted: Color(0xFF1B3054),
    sidebarText: Color(0xFFCBD5E1),
    sidebarTextActive: Color(0xFFFFFFFF),
    shadow: Color(0xFF0F172A),
  );

  static const dark = AppPalette(
    background: Color(0xFF101418),
    backgroundTint: Color(0xFF161C22),
    surface: Color(0xFF181E25),
    surfaceMuted: Color(0xFF212833),
    panel: Color(0xFF141A20),
    border: Color(0xFF2C3542),
    divider: Color(0xFF262E38),
    text: Color(0xFFE7EDF3),
    textSecondary: Color(0xFF9AA6B4),
    textTertiary: Color(0xFF6E7C8C),
    primary: Color(0xFF3B82F6),
    primaryHover: Color(0xFF60A5FA),
    primarySoft: Color(0xFF1E3A5F),
    primaryMuted: Color(0xFF172554),
    success: Color(0xFF3DDC97),
    successSoft: Color(0xFF14352A),
    warning: Color(0xFFE6B15A),
    warningSoft: Color(0xFF3A2C14),
    danger: Color(0xFFF07178),
    dangerSoft: Color(0xFF3A1E24),
    neutralSoft: Color(0xFF242C36),
    sidebar: Color(0xFF0B1220),
    sidebarEnd: Color(0xFF0B1220),
    sidebarMuted: Color(0xFF172033),
    sidebarText: Color(0xFFC5D0DA),
    sidebarTextActive: Color(0xFFFFFFFF),
    shadow: Color(0xFF000000),
  );
}

/// Avisa a árvore quando o modo muda, para os widgets que usam [AppColors].
class PaletteScope extends InheritedWidget {
  const PaletteScope({required this.dark, required super.child, super.key});

  final bool dark;

  static bool of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    return scope?.dark ?? false;
  }

  @override
  bool updateShouldNotify(PaletteScope oldWidget) => dark != oldWidget.dark;
}

/// Cores do modo atual. Chame [watch] no início do build que as usa.
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;

  static void bind(bool dark) => _p = dark ? AppPalette.dark : AppPalette.light;

  static void watch(BuildContext context) => bind(PaletteScope.of(context));

  static bool get isDark => identical(_p, AppPalette.dark);

  static Color get background => _p.background;
  static Color get backgroundTint => _p.backgroundTint;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get panel => _p.panel;
  static Color get border => _p.border;
  static Color get divider => _p.divider;
  static Color get text => _p.text;
  static Color get textSecondary => _p.textSecondary;
  static Color get textTertiary => _p.textTertiary;
  static Color get primary => _p.primary;
  static Color get primaryHover => _p.primaryHover;
  static Color get primarySoft => _p.primarySoft;
  static Color get primaryMuted => _p.primaryMuted;
  static Color get success => _p.success;
  static Color get successSoft => _p.successSoft;
  static Color get warning => _p.warning;
  static Color get warningSoft => _p.warningSoft;
  static Color get danger => _p.danger;
  static Color get dangerSoft => _p.dangerSoft;
  static Color get neutralSoft => _p.neutralSoft;
  static Color get sidebar => _p.sidebar;
  static Color get sidebarEnd => _p.sidebarEnd;
  static Color get sidebarMuted => _p.sidebarMuted;
  static Color get sidebarText => _p.sidebarText;
  static Color get sidebarTextActive => _p.sidebarTextActive;
  static Color get shadow => _p.shadow;
}
