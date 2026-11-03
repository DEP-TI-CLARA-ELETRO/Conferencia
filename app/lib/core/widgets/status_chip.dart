import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusTone { success, warning, danger, neutral, info }

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
