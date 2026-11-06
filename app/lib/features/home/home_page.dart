import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/page_header.dart';
import '../auth/auth_controller.dart';
import '../shell/shell_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.watch(context);
    final user = ref.watch(authControllerProvider).user;
    final range = ref.watch(selectedDateRangeProvider);
    final store = ref.watch(selectedStoreProvider);
    final unit = ref.watch(selectedBusinessUnitProvider);
    final firstName = (user?.name ?? '').split(' ').first;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final scope = store?.name ?? unit?.shortLabel ?? 'Todas as lojas';

    final kpis = [
      const KpiTile(
        label: 'Total de caixas',
        value: '10',
        caption: '8 já fechados',
        icon: Icons.inbox_outlined,
      ),
      KpiTile(
        label: 'Conferidos',
        value: '6',
        caption: '60% do total',
        valueColor: AppColors.success,
        icon: Icons.verified_outlined,
      ),
      KpiTile(
        label: 'Em conferência',
        value: '2',
        valueColor: AppColors.warning,
        icon: Icons.hourglass_top_rounded,
      ),
      KpiTile(
        label: 'Com divergência',
        value: '1',
        valueColor: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      ),
      KpiTile(
        label: 'Total de vendas',
        value: formatMoney(29432.50),
        caption: 'PDV',
        icon: Icons.payments_outlined,
      ),
      KpiTile(
        label: 'Diferença total',
        value: formatDiff(-63.30),
        valueColor: AppColors.danger,
        icon: Icons.swap_vert_rounded,
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, narrow ? 20 : 28, narrow ? 16 : 28, 40),
      children: [
        PageHeader(
          title: '${_greeting()}, $firstName',
          subtitle: '$scope · ${formatLongDateRange(range.from, range.to)}',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 420 ? 2 : 1);
            const gap = 14.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final k in kpis) SizedBox(width: w, child: k)],
            );
          },
        ),
        const SizedBox(height: 24),
        const _StageProgress(),
        const SizedBox(height: 14),
        Text(
          'Dados de exemplo, apenas para validar o layout.',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    const done = {
      ClosingStage.pdvImported: 10,
      ClosingStage.fiscal: 8,
      ClosingStage.treasury: 6,
      ClosingStage.manager: 4,
      ClosingStage.supervisor: 2,
      ClosingStage.audit: 1,
      ClosingStage.done: 0,
    };
    const total = 10;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Andamento por etapa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(
            'Quantos caixas já passaram por cada etapa',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 22),
          for (final stage in ClosingStage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      stage.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: done[stage]! / total,
                        minHeight: 8,
                        backgroundColor: AppColors.neutralSoft,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${done[stage]}/$total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
