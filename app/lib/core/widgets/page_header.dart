import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../theme/app_colors.dart';
import '../theme/brand_scope.dart';

/// Cabeçalho de página: título + subtítulo + ações.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < 640 && trailing != null;
        final onBrand = BrandScope.unitOf(context) == BusinessUnit.posto;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: onBrand ? Colors.white : AppColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  color: onBrand ? const Color(0xFFFFE4E6) : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              trailing!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            if (onBrand && c.maxWidth > 760) ...[
              const Padding(
                padding: EdgeInsets.only(right: 28, bottom: 2),
                child: Image(
                  image: AssetImage('assets/brands/postos_gr.png'),
                  height: 54,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            ?trailing,
          ],
        );
      },
    );
  }
}
