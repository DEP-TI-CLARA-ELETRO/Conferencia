import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';
import '../shell/shell_providers.dart';
import 'closings_controller.dart';

/// Página "Caixas do dia".
class ClosingsPage extends ConsumerWidget {
  const ClosingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final ui = ref.watch(closingsControllerProvider);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, narrow ? 20 : 28, narrow ? 16 : 28, 40),
      children: [
        PageHeader(
          title: 'Caixas do dia',
          subtitle: formatLongDate(date),
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: ui.loading || ui.syncing
                    ? null
                    : () => ref.read(closingsControllerProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
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
                    : const Icon(Icons.cloud_download_rounded, size: 18),
                label: Text(ui.syncing ? 'Sincronizando…' : 'Sincronizar WebPosto'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
        if (ui.loading)
          const Padding(
            padding: EdgeInsets.all(64),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (ui.items.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum caixa nesta data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sincronize o WebPosto ou escolha outro dia na barra superior.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (!narrow)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${ui.items.length} caixa${ui.items.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _HeaderRow(),
                for (var i = 0; i < ui.items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  _ClosingRow(ui.items[i]),
                ],
              ],
            ),
          ),
        ],
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
      _ => AppColors.primaryMuted,
    };
    final fg = switch (tone) {
      StatusTone.success => AppColors.success,
      StatusTone.danger => AppColors.danger,
      StatusTone.warning => AppColors.warning,
      _ => AppColors.primary,
    };
    final icon = switch (tone) {
      StatusTone.success => Icons.check_circle_outline_rounded,
      StatusTone.danger => Icons.error_outline_rounded,
      StatusTone.warning => Icons.info_outline_rounded,
      _ => Icons.info_outline_rounded,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

const _headStyle = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 760) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: const Row(
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
    final title = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.point_of_sale_rounded, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Caixa ${c.caixaCodigo}${c.pdvCode != null ? ' · PDV ${c.pdvCode}' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
              ),
              const SizedBox(height: 2),
              Text(
                c.storeName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Expanded(flex: 3, child: title),
            Expanded(
              flex: 2,
              child: Text(
                c.shiftLabel ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                c.apurado == null ? '—' : formatMoney(c.apurado!),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                diffText,
                textAlign: TextAlign.right,
                style: TextStyle(color: diffColor, fontWeight: FontWeight.w700, fontSize: 14),
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
          Row(children: [Expanded(child: title), const SizedBox(width: 8), chip]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apurado', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      c.apurado == null ? '—' : formatMoney(c.apurado!),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Diferença', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      diffText,
                      style: TextStyle(color: diffColor, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
