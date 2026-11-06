import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fundo neutro da área de conteúdo.
class GroupBackdrop extends StatelessWidget {
  const GroupBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return ColoredBox(color: AppColors.background, child: child);
  }
}
