import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

/// Card pequeno de indicador (KPI): rótulo + valor grande + legenda opcional.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
  });

  final String label; // ex.: "Conferidos"
  final String value; // ex.: "6" ou "R$ 100,00"
  final String? caption; // texto menor embaixo (opcional)
  final Color? valueColor; // cor do valor (opcional; senão usa texto padrão)

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // alinha à esquerda
        mainAxisSize: MainAxisSize.min, // altura só do necessário
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              // ?? = se valueColor for null, usa AppColors.text
              color: valueColor ?? AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          // Só mostra a legenda se caption não for null
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!, // ! = "eu sei que não é null aqui"
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
