import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusTone { success, warning, danger, neutral, info }

/// Pílula de status discreta.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  (Color fg, Color bg) get _colors => switch (tone) {
        StatusTone.success => (AppColors.success, AppColors.successSoft),
        StatusTone.warning => (AppColors.warning, AppColors.warningSoft),
        StatusTone.danger => (AppColors.danger, AppColors.dangerSoft),
        StatusTone.info => (AppColors.primary, AppColors.primarySoft),
        StatusTone.neutral => (AppColors.textSecondary, AppColors.neutralSoft),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
