import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/brand_scope.dart';

/// Fundo da área de conteúdo conforme o grupo selecionado.
class GroupBackdrop extends StatelessWidget {
  const GroupBackdrop({super.key, required this.unit, required this.child});

  final BusinessUnit? unit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (unit != BusinessUnit.posto) {
      return ColoredBox(color: AppColors.background, child: child);
    }

    return BrandScope(
      unit: unit,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFC81E1E),
              Color(0xFF9B1515),
              Color(0xFF7A1010),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -60,
              bottom: -30,
              child: _PostosMark(width: 640, opacity: 0.2),
            ),
            const Positioned(
              left: -40,
              top: 120,
              child: _PostosMark(width: 360, opacity: 0.1),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _PostosMark extends StatelessWidget {
  const _PostosMark({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          'assets/brands/postos_gr.png',
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
