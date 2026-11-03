import 'package:flutter/material.dart';

/// Paleta de cores do app (estilo limpo: neutros + um azul de destaque).
///
/// abstract final class = "caixa de constantes"; não se instancia (sem new AppColors()).
/// Tudo é static const = valor fixo, acessado como AppColors.primary.
abstract final class AppColors {
  static const background = Color(0xFFF5F5F7); // fundo cinza bem claro
  static const surface = Colors.white; // cartões / superfícies
  static const border = Color(0xFFE5E5EA); // bordas suaves
  static const divider = Color(0xFFEFEFF2); // linhas divisórias

  static const text = Color(0xFF1D1D1F); // texto principal (quase preto)
  static const textSecondary = Color(0xFF6E6E73); // texto secundário
  static const textTertiary = Color(0xFF9A9AA0); // texto bem discreto

  static const primary = Color(0xFF0071E3); // azul de destaque (botões, links)
  static const primarySoft = Color(0xFFE8F1FC); // azul bem clarinho (fundos)

  // Cores de status (sucesso / aviso / erro) + versões "suaves" para chips
  static const success = Color(0xFF1E8E4E);
  static const successSoft = Color(0xFFE7F5EC);
  static const warning = Color(0xFFB36B00);
  static const warningSoft = Color(0xFFFFF3DD);
  static const danger = Color(0xFFD12F3A);
  static const dangerSoft = Color(0xFFFCEAEC);
  static const neutralSoft = Color(0xFFEEEEF1);
}
