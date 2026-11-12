import 'package:flutter/material.dart';

/// Paleta glass: verde floresta + mint + fundo creme suave.
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
    required this.accentWarm,
    required this.glowMint,
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
  final Color accentWarm;
  final Color glowMint;

  static const light = AppPalette(
    background: Color(0xFFF3F1EB),
    backgroundTint: Color(0xFFE8F0EA),
    surface: Color(0xF2FFFFFF),
    surfaceMuted: Color(0xE8F7F8F5),
    panel: Color(0xF7FFFFFF),
    border: Color(0x33FFFFFF),
    divider: Color(0x1A0F172A),
    text: Color(0xFF14201C),
    textSecondary: Color(0xFF5B6B64),
    textTertiary: Color(0xFF8A9A92),
    primary: Color(0xFF1F4D3A),
    primaryHover: Color(0xFF2F6B52),
    primarySoft: Color(0xFFD7F0E4),
    primaryMuted: Color(0xFFEAF7F0),
    success: Color(0xFF1F8A5B),
    successSoft: Color(0xFFD7F5E8),
    warning: Color(0xFFB45309),
    warningSoft: Color(0xFFFFF0D6),
    danger: Color(0xFFC2414B),
    dangerSoft: Color(0xFFFFE4E6),
    neutralSoft: Color(0xFFE8EEE9),
    sidebar: Color(0xFF16382C),
    sidebarEnd: Color(0xFF0F2A21),
    sidebarMuted: Color(0xFF255544),
    sidebarText: Color(0xFFC8DED4),
    sidebarTextActive: Color(0xFFFFFFFF),
    shadow: Color(0xFF16382C),
    accentWarm: Color(0xFFE8A07A),
    glowMint: Color(0xFF7ED9B0),
  );

  static const dark = AppPalette(
    background: Color(0xFF0F1714),
    backgroundTint: Color(0xFF15221C),
    surface: Color(0xCC1A2621),
    surfaceMuted: Color(0xB322302A),
    panel: Color(0xE616221D),
    border: Color(0x33FFFFFF),
    divider: Color(0x1AFFFFFF),
    text: Color(0xFFE8F2EC),
    textSecondary: Color(0xFFA3B5AC),
    textTertiary: Color(0xFF71857A),
    primary: Color(0xFF5ECF9A),
    primaryHover: Color(0xFF7ED9B0),
    primarySoft: Color(0xFF1A3A2E),
    primaryMuted: Color(0xFF152E25),
    success: Color(0xFF5ECF9A),
    successSoft: Color(0xFF1A3A2E),
    warning: Color(0xFFE6B15A),
    warningSoft: Color(0xFF3A2C14),
    danger: Color(0xFFF07178),
    dangerSoft: Color(0xFF3A1E24),
    neutralSoft: Color(0xFF24302A),
    sidebar: Color(0xFF0C1713),
    sidebarEnd: Color(0xFF0C1713),
    sidebarMuted: Color(0xFF1A2E25),
    sidebarText: Color(0xFFC5D8CF),
    sidebarTextActive: Color(0xFFFFFFFF),
    shadow: Color(0xFF000000),
    accentWarm: Color(0xFFE8A07A),
    glowMint: Color(0xFF7ED9B0),
  );
}

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
  static Color get accentWarm => _p.accentWarm;
  static Color get glowMint => _p.glowMint;
}
