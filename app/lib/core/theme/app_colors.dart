import 'package:flutter/material.dart';

/// Paleta minimalista: neutros claros + um unico azul de destaque.
abstract final class AppColors {
  static const background = Color(0xFFF5F5F7);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E5EA);
  static const divider = Color(0xFFEFEFF2);

  static const text = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFF9A9AA0);

  static const primary = Color(0xFF0071E3);
  static const primarySoft = Color(0xFFE8F1FC);

  static const success = Color(0xFF1E8E4E);
  static const successSoft = Color(0xFFE7F5EC);
  static const warning = Color(0xFFB36B00);
  static const warningSoft = Color(0xFFFFF3DD);
  static const danger = Color(0xFFD12F3A);
  static const dangerSoft = Color(0xFFFCEAEC);
  static const neutralSoft = Color(0xFFEEEEF1);
}
