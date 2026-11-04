import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';
import '../shell/shell_providers.dart';
import 'closings_controller.dart';

/// Página "Caixas do dia" — dados importados (WebPosto) ou vazios até sincronizar.
class ClosingsPage extends ConsumerWidget {
  const ClosingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final ui = ref.watch(closingsControllerProvider);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 28),
      children: [
        PageHeader(
          title: 'Caixas do dia',
          subtitle: formatLongDate(date),
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: ui.loading || ui.syncing
                    ? null
                    : () => ref.read(closingsControllerProvider.notifier).load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Atualizar'),
              ),
              FilledButton.icon(
                onPressed: ui.syncing || !ui.webpostoReady
                    ? null
                    : () => ref.read(closingsControllerProvider.notifier).syncWebposto(),
                icon: ui.syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(ui.syncing ? 'Sincronizando…' : 'Sincronizar WebPosto'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!ui.webpostoReady)
          const _HintBanner(
            text:
                'Coloque WEBPOSTO_CHAVE no server/.env e reinicie a API para habilitar a sincronização dos postos.',
            tone: StatusTone.warning,
          ),
        if (ui.syncMessage != null) ...[
          const SizedBox(height: 8),
          _HintBanner(text: ui.syncMessage!, tone: StatusTone.success),
        ],
        if (ui.error != null) ...[
          const SizedBox(height: 8),
          _HintBanner(text: ui.error!, tone: StatusTone.danger),
        ],
        const SizedBox(height: 16),
        if (ui.loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (ui.items.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum caixa nesta data.\nSincronize o WebPosto ou escolha outro dia na barra superior.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _HeaderRow(),
                for (final c in ui.items) ...[
                  const Divider(height: 1),
                  _ClosingRow(c),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.text, required this.tone});
  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      StatusTone.success => AppColors.successSoft,
      StatusTone.danger => AppColors.dangerSoft,
      StatusTone.warning => AppColors.warningSoft,
      _ => AppColors.primarySoft,
    };
    final fg = switch (tone) {
      StatusTone.success => AppColors.success,
      StatusTone.danger => AppColors.danger,
      StatusTone.warning => AppColors.warning,
      _ => AppColors.primary,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13)),
    );
  }
}

const _headStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 760) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('CAIXA / LOJA', style: _headStyle)),
          Expanded(flex: 2, child: Text('TURNO', style: _headStyle)),
          Expanded(flex: 2, child: Text('APURADO', style: _headStyle, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('DIFERENÇA', style: _headStyle, textAlign: TextAlign.right)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('SITUAÇÃO', style: _headStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingRow extends StatelessWidget {
  const _ClosingRow(this.c);
  final ClosingDto c;

  StatusTone get _tone {
    if (!c.closed) return StatusTone.neutral;
    final d = c.diferenca ?? 0;
    if (d.abs() < 0.009) return StatusTone.success;
    return StatusTone.danger;
  }

  String get _statusLabel {
    if (!c.closed) return 'Aberto';
    if (c.consolidated) return 'Consolidado';
    final d = c.diferenca ?? 0;
    if (d.abs() < 0.009) return 'Fechado';
    return 'Divergência';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caixa ${c.caixaCodigo}${c.pdvCode != null ? ' · PDV ${c.pdvCode}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(c.storeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
    final chip = StatusChip(_statusLabel, tone: _tone);
    final diff = c.diferenca;
    final diffText = diff == null ? '—' : formatDiff(diff);
    final diffColor = (diff == null || diff == 0)
        ? AppColors.textSecondary
        : (diff < 0 ? AppColors.danger : AppColors.success);

    if (wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 3, child: title),
            Expanded(flex: 2, child: Text(c.shiftLabel ?? '—')),
            Expanded(
              flex: 2,
              child: Text(
                c.apurado == null ? '—' : formatMoney(c.apurado!),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                diffText,
                textAlign: TextAlign.right,
                style: TextStyle(color: diffColor, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: chip)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: title), chip]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c.apurado == null ? '—' : formatMoney(c.apurado!),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(diffText, style: TextStyle(color: diffColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
