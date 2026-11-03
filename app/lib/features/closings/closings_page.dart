import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';
import '../shell/shell_providers.dart';
import 'closing_sample.dart';

class ClosingsPage extends ConsumerStatefulWidget {
  const ClosingsPage({super.key});

  @override
  ConsumerState<ClosingsPage> createState() => _ClosingsPageState();
}

class _ClosingsPageState extends ConsumerState<ClosingsPage> {
  SampleStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final rows = closingSamples.where((c) => _filter == null || c.status == _filter).toList();

    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        PageHeader(title: 'Caixas do dia', subtitle: formatLongDate(date)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Todos (${closingSamples.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final s in SampleStatus.values)
              ChoiceChip(
                label: Text(s.label),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _HeaderRow(),
              for (final c in rows) ...[
                const Divider(height: 1),
                _ClosingRow(c),
              ],
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum caixa neste filtro.', style: TextStyle(color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dados de exemplo, apenas para validar o layout.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

const _headStyle = TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 760) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('CAIXA', style: _headStyle)),
          Expanded(flex: 2, child: Text('HORÁRIO', style: _headStyle)),
          Expanded(flex: 2, child: Text('PREVISTO', style: _headStyle, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('CONFERIDO', style: _headStyle, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('DIFERENÇA', style: _headStyle, textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('SITUAÇÃO', style: _headStyle))),
        ],
      ),
    );
  }
}

class _ClosingRow extends StatelessWidget {
  const _ClosingRow(this.c);

  final ClosingSample c;

  Color _diffColor(double? d) {
    if (d == null || d == 0) return AppColors.textSecondary;
    return d < 0 ? AppColors.danger : AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final diff = c.difference;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Caixa ${c.register}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(c.operator, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
    final chip = StatusChip(c.status.label, tone: c.status.tone);
    final diffText = diff == null ? '—' : formatDiff(diff);

    if (wide) {
      return InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(flex: 3, child: title),
              Expanded(flex: 2, child: Text('${c.opened} – ${c.closed}')),
              Expanded(flex: 2, child: Text(formatMoney(c.expected), textAlign: TextAlign.right)),
              Expanded(
                flex: 2,
                child: Text(
                  c.counted == null ? '—' : formatMoney(c.counted!),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  diffText,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: _diffColor(diff), fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: chip)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: title), chip]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatMoney(c.expected), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  diffText,
                  style: TextStyle(color: _diffColor(diff), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
