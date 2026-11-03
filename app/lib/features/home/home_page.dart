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

/// Página Início: saudação + KPIs de exemplo + andamento por etapa.
/// ConsumerWidget = sem estado local; só observa Riverpod.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Escolhe saudação conforme a hora do dia.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final date = ref.watch(selectedDateProvider);
    final store = ref.watch(selectedStoreProvider);
    // "Maria Silva" -> "Maria"
    final firstName = (user?.name ?? '').split(' ').first;
    final narrow = MediaQuery.sizeOf(context).width < 600;

    // Dados FICTÍCIOS — só para validar o layout (depois virão da API).
    final kpis = [
      const KpiTile(label: 'Total de caixas', value: '10', caption: '8 já fechados'),
      const KpiTile(label: 'Conferidos', value: '6', caption: '60% do total', valueColor: AppColors.success),
      const KpiTile(label: 'Em conferência', value: '2', valueColor: AppColors.warning),
      const KpiTile(label: 'Com divergência', value: '1', valueColor: AppColors.danger),
      // Estes NÃO são const porque formatMoney roda em tempo de execução
      KpiTile(label: 'Total de vendas', value: formatMoney(29432.50), caption: 'PDV'),
      KpiTile(label: 'Diferença total', value: formatDiff(-63.30), valueColor: AppColors.danger),
    ];

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 28),
      children: [
        PageHeader(
          // Interpolação: $variavel e ${expressão}
          title: '${_greeting()}, $firstName',
          subtitle: '${store?.name ?? ''} · ${formatLongDate(date)}',
        ),
        const SizedBox(height: 24),
        // LayoutBuilder = "me diga a largura disponível e eu decido as colunas"
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 420 ? 2 : 1);
            const gap = 16.0;
            // Largura de cada card = (total - gaps) / colunas
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap, // espaço horizontal
              runSpacing: gap, // espaço vertical entre linhas
              children: [for (final k in kpis) SizedBox(width: w, child: k)],
            );
          },
        ),
        const SizedBox(height: 24),
        const _StageProgress(),
        const SizedBox(height: 12),
        const Text(
          'Dados de exemplo, apenas para validar o layout.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Bloco "Andamento por etapa" (barras de progresso de exemplo).
class _StageProgress extends StatelessWidget {
  const _StageProgress();

  @override
  Widget build(BuildContext context) {
    // Map: etapa -> quantos caixas já passaram por ela (fictício)
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
          const Text('Andamento por etapa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Quantos caixas já passaram por cada etapa',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Uma linha por valor do enum ClosingStage
          for (final stage in ClosingStage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(stage.label, style: const TextStyle(fontSize: 14)),
                  ),
                  Expanded(
                    // Expanded = a barra come o espaço do meio
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: done[stage]! / total, // 0.0 a 1.0
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
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
