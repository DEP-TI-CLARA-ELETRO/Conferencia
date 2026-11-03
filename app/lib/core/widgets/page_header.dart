import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cabeçalho de página: título grande + subtítulo + área opcional à direita.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing; // botão/ação à direita (opcional)

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // alinha pela base
      children: [
        Expanded(
          // Expanded = ocupa todo o espaço horizontal que sobrar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ],
            ],
          ),
        ),
        // ?trailing = inclui o widget só se não for null (sintaxe Dart recente)
        ?trailing,
      ],
    );
  }
}
