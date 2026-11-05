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

enum _SortColumn { apurado, diferenca, situacao }

enum _SortDir { desc, asc }

/// Página "Caixas do dia".
class ClosingsPage extends ConsumerStatefulWidget {
  const ClosingsPage({super.key});

  @override
  ConsumerState<ClosingsPage> createState() => _ClosingsPageState();
}

class _ClosingsPageState extends ConsumerState<ClosingsPage> {
  _SortColumn? _sortColumn;
  _SortDir? _sortDir;

  void _cycleSort(_SortColumn column) {
    setState(() {
      if (_sortColumn != column) {
        _sortColumn = column;
        _sortDir = _SortDir.desc;
        return;
      }
      if (_sortDir == _SortDir.desc) {
        _sortDir = _SortDir.asc;
        return;
      }
      _sortColumn = null;
      _sortDir = null;
    });
  }

  List<ClosingDto> _sorted(List<ClosingDto> items) {
    final column = _sortColumn;
    final dir = _sortDir;
    if (column == null || dir == null) return items;
    final copy = [...items];
    copy.sort((a, b) {
      final cmp = switch (column) {
        _SortColumn.apurado => _compareNullable(a.apurado, b.apurado),
        _SortColumn.diferenca => _compareNullable(a.diferenca, b.diferenca),
        _SortColumn.situacao => _statusRank(a).compareTo(_statusRank(b)),
      };
      return dir == _SortDir.desc ? -cmp : cmp;
    });
    return copy;
  }

  /// Nulos ficam no fim, mesmo quando a ordem inverte.
  int _compareNullable(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return _sortDir == _SortDir.desc ? -1 : 1;
    if (b == null) return _sortDir == _SortDir.desc ? 1 : -1;
    return a.compareTo(b);
  }

  int _statusRank(ClosingDto c) => switch (_kindOf(c)) {
        _BoxKind.divergent => 3,
        _BoxKind.open => 2,
        _BoxKind.closed => 1,
        _BoxKind.consolidated => 0,
      };

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(selectedDateRangeProvider);
    final ui = ref.watch(closingsControllerProvider);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, narrow ? 20 : 28, narrow ? 16 : 28, 40),
      children: [
        PageHeader(
          title: 'Caixas do dia',
          subtitle: formatLongDateRange(range.from, range.to),
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
          _StatusSummary(items: ui.items),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _HeaderRow(
                  column: _sortColumn,
                  dir: _sortDir,
                  onSort: _cycleSort,
                ),
                for (final (i, item) in _sorted(ui.items).indexed) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  _ClosingRow(item),
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
  const _HeaderRow({required this.column, required this.dir, required this.onSort});

  final _SortColumn? column;
  final _SortDir? dir;
  final ValueChanged<_SortColumn> onSort;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 760) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('CAIXA / LOJA', style: _headStyle)),
          const Expanded(flex: 2, child: Text('TURNO', style: _headStyle)),
          Expanded(
            flex: 2,
            child: _SortLabel(
              label: 'APURADO',
              alignEnd: true,
              active: column == _SortColumn.apurado,
              dir: column == _SortColumn.apurado ? dir : null,
              onTap: () => onSort(_SortColumn.apurado),
            ),
          ),
          Expanded(
            flex: 2,
            child: _SortLabel(
              label: 'DIFERENÇA',
              alignEnd: true,
              active: column == _SortColumn.diferenca,
              dir: column == _SortColumn.diferenca ? dir : null,
              onTap: () => onSort(_SortColumn.diferenca),
            ),
          ),
          Expanded(
            flex: 2,
            child: _SortLabel(
              label: 'SITUAÇÃO',
              alignEnd: true,
              active: column == _SortColumn.situacao,
              dir: column == _SortColumn.situacao ? dir : null,
              onTap: () => onSort(_SortColumn.situacao),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortLabel extends StatelessWidget {
  const _SortLabel({
    required this.label,
    required this.active,
    required this.dir,
    required this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final bool active;
  final _SortDir? dir;
  final VoidCallback onTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    final icon = switch (dir) {
      _SortDir.desc => Icons.arrow_downward_rounded,
      _SortDir.asc => Icons.arrow_upward_rounded,
      null => Icons.unfold_more_rounded,
    };
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _headStyle.copyWith(color: color)),
              const SizedBox(width: 2),
              Icon(icon, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BoxKind { open, divergent, consolidated, closed }

_BoxKind _kindOf(ClosingDto c) {
  if (!c.closed) return _BoxKind.open;
  final d = c.diferenca ?? 0;
  if (d.abs() >= 0.01) return _BoxKind.divergent;
  if (c.consolidated) return _BoxKind.consolidated;
  return _BoxKind.closed;
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.items});
  final List<ClosingDto> items;

  @override
  Widget build(BuildContext context) {
    var open = 0, divergent = 0, consolidated = 0, closed = 0;
    for (final c in items) {
      switch (_kindOf(c)) {
        case _BoxKind.open:
          open++;
        case _BoxKind.divergent:
          divergent++;
        case _BoxKind.consolidated:
          consolidated++;
        case _BoxKind.closed:
          closed++;
      }
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountPill('${items.length} caixas', AppColors.textSecondary, AppColors.neutralSoft),
        if (divergent > 0) _CountPill('$divergent divergência', AppColors.danger, AppColors.dangerSoft),
        if (consolidated > 0)
          _CountPill('$consolidated consolidado', AppColors.primary, AppColors.primarySoft),
        if (closed > 0) _CountPill('$closed fechado', AppColors.success, AppColors.successSoft),
        if (open > 0) _CountPill('$open aberto', AppColors.warning, AppColors.warningSoft),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.label, this.fg, this.bg);
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ClosingRow extends StatelessWidget {
  const _ClosingRow(this.c);
  final ClosingDto c;

  _BoxKind get _kind => _kindOf(c);

  StatusTone get _tone => switch (_kind) {
        _BoxKind.open => StatusTone.warning,
        _BoxKind.divergent => StatusTone.danger,
        _BoxKind.consolidated => StatusTone.info,
        _BoxKind.closed => StatusTone.success,
      };

  String get _statusLabel => switch (_kind) {
        _BoxKind.open => 'Aberto',
        _BoxKind.divergent => 'Divergência',
        _BoxKind.consolidated => 'Consolidado',
        _BoxKind.closed => 'Fechado',
      };

  (Color fg, Color bg) get _paint => switch (_kind) {
        _BoxKind.open => (AppColors.warning, AppColors.warningSoft),
        _BoxKind.divergent => (AppColors.danger, AppColors.dangerSoft),
        _BoxKind.consolidated => (AppColors.primary, AppColors.primarySoft),
        _BoxKind.closed => (AppColors.success, AppColors.successSoft),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final title = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _paint.$2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.point_of_sale_rounded, size: 18, color: _paint.$1),
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
                '${c.storeName} · ${c.movementDate.split('-').reversed.join('/')}',
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

    final (accent, wash) = _paint;

    if (wide) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: wash.withValues(alpha: _kind == _BoxKind.divergent ? 0.72 : 0.45),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 22, 14),
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
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: wash.withValues(alpha: 0.55),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Padding(
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
      ),
    );
  }
}
