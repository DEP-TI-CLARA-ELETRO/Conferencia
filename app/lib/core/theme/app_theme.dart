import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema glass: cantos bem arredondados, botões em pílula, sombra suave.
abstract final class AppTheme {
  static const radius = 28.0;
  static const radiusSm = 18.0;
  static const radiusPill = 999.0;

  static List<BoxShadow> get softShadow {
    final dark = AppColors.isDark;
    return [
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: dark ? 0.45 : 0.08),
        blurRadius: 32,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: dark ? 0.25 : 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final onPrimary = brightness == Brightness.dark ? const Color(0xFF0F1714) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: onPrimary,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
      outline: c.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.surface,
      dividerColor: c.divider,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: c.textSecondary),
    );

    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: c.text,
      displayColor: c.text,
    );

    OutlineInputBorder border(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -1.0,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
      ),
      dividerTheme: DividerThemeData(color: c.divider, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.primary, width: 1.5),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger, width: 1.5),
        labelStyle: TextStyle(color: c.textSecondary),
        hintStyle: TextStyle(color: c.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          backgroundColor: c.surface,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.panel,
        elevation: 12,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.shadow.withValues(alpha: brightness == Brightness.dark ? 0.4 : 0.12),
        textStyle: TextStyle(color: c.text, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: c.sidebar),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.panel,
        headerBackgroundColor: c.primaryMuted,
        headerForegroundColor: c.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }
}
