import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Cartão branco com borda suave — bloco visual básico do layout.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child, // conteúdo interno (obrigatório)
    this.padding = const EdgeInsets.all(20), // padrão: 20px em todos os lados
    this.onTap, // se não for null, o card fica clicável
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap; // tipo "função sem parâmetros e sem retorno"

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radius);
    // Material + InkWell = fundo + efeito de onda ao tocar
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias, // corta o ripple nas bordas arredondadas
      child: InkWell(
        onTap: onTap, // null = não clicável
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
