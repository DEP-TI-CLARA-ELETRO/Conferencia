import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "Tom" visual do chip (define cor do texto e do fundo).
enum StatusTone { success, warning, danger, neutral, info }

/// Pílula de status (ex.: "Concluído", "Divergência").
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  /// Devolve um par (cor do texto, cor do fundo) conforme o tom.
  /// Record (Color, Color) em Dart 3.
  (Color fg, Color bg) get _colors => switch (tone) {
        // switch expression: cada caso devolve um valor
        StatusTone.success => (AppColors.success, AppColors.successSoft),
        StatusTone.warning => (AppColors.warning, AppColors.warningSoft),
        StatusTone.danger => (AppColors.danger, AppColors.dangerSoft),
        StatusTone.info => (AppColors.primary, AppColors.primarySoft),
        StatusTone.neutral => (AppColors.textSecondary, AppColors.neutralSoft),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors; // desestrutura o record em duas variáveis
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min, // só a largura do conteúdo
        children: [
          // Bolinha colorida
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
