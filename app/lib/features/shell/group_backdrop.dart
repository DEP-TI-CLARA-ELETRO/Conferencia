import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fundo ambient do conteúdo: creme + manchas mint/pêssego suaves.
class GroupBackdrop extends StatelessWidget {
  const GroupBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final dark = AppColors.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0F1714), Color(0xFF15221C), Color(0xFF101A16)]
              : const [Color(0xFFF6F3EC), Color(0xFFEEF5F0), Color(0xFFF8EEE6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Blob(
              size: 340,
              color: (dark ? AppColors.glowMint : const Color(0xFFB8E6CF)).withValues(alpha: dark ? 0.12 : 0.45),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _Blob(
              size: 300,
              color: (dark ? AppColors.accentWarm : const Color(0xFFF0C9B0)).withValues(alpha: dark ? 0.10 : 0.40),
            ),
          ),
          Positioned(
            top: 220,
            left: 180,
            child: _Blob(
              size: 180,
              color: (dark ? AppColors.primaryHover : const Color(0xFFD5E8F4)).withValues(alpha: dark ? 0.08 : 0.35),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
