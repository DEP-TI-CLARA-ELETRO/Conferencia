import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Painel do caixa: resumo, formas de pagamento e vendas.
class ClosingDetailDialog extends StatefulWidget {
  const ClosingDetailDialog({super.key, required this.closing, required this.load});

  final ClosingDto closing;
  final Future<ClosingDetailDto> Function() load;

  @override
  State<ClosingDetailDialog> createState() => _ClosingDetailDialogState();
}

class _ClosingDetailDialogState extends State<ClosingDetailDialog> {
  ClosingDetailDto? _detail;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final detail = await widget.load();
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = detail.warning;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final c = widget.closing;
    final open = !c.closed;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: size.height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(closing: c, open: open),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        final stack = box.maxWidth < 720;
                        final summary = _SummaryCard(
                          closing: c,
                          employeeName: _detail?.employeeName,
                          loadingName: _loading,
                        );
                        final payments = _PaymentsCard(
                          loading: _loading,
                          detail: _detail,
                          error: _error,
                        );
                        if (stack) {
                          return Column(
                            children: [
                              summary,
                              const SizedBox(height: 12),
                              payments,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: summary),
                            const SizedBox(width: 12),
                            Expanded(child: payments),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _SalesTable(loading: _loading, detail: _detail, error: _error),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.closing, required this.open});

  final ClosingDto closing;
  final bool open;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final date = closing.movementDate.split('-').reversed.join('/');
    final shift = _shiftLabel(closing.shiftLabel);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caixa #${closing.caixaCodigo} — $shift',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${closing.storeName} · $date',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(open: open),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final fg = open ? AppColors.warning : AppColors.success;
    final bg = open ? AppColors.warningSoft : AppColors.successSoft;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        open ? 'ABERTO' : 'FECHADO',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.closing,
    required this.employeeName,
    required this.loadingName,
  });

  final ClosingDto closing;
  final String? employeeName;
  final bool loadingName;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final diff = closing.diferenca;
    final diffColor = diff == null || diff == 0
        ? AppColors.text
        : (diff < 0 ? AppColors.danger : AppColors.success);
    final name = loadingName
        ? '…'
        : (employeeName == null || employeeName!.trim().isEmpty)
            ? '—'
            : employeeName!.toUpperCase();

    return _PanelCard(
      title: 'RESUMO DO CAIXA',
      child: Column(
        children: [
          _Line('Usuário responsável', name, emphasize: true),
          _Line('PDV (cod.)', closing.pdvCode == null ? '—' : '#${closing.pdvCode}'),
          _Line('Abertura', _stamp(closing.openedAt)),
          _Line('Fechamento', _stamp(closing.closedAt)),
          _Line(
            'Total apurado',
            closing.apurado == null ? '—' : formatMoney(closing.apurado!),
            emphasize: true,
          ),
          _Line(
            'Diferença',
            diff == null ? '—' : _panelDiff(diff),
            emphasize: true,
            valueColor: diffColor,
          ),
        ],
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.loading, required this.detail, required this.error});

  final bool loading;
  final ClosingDetailDto? detail;
  final String? error;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final payments = detail?.payments ?? const <ClosingPaymentLineDto>[];
    return _PanelCard(
      title: 'FORMAS DE PAGAMENTO (VENDAS DO CAIXA)',
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : payments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    error ?? 'Sem vendas vinculadas a este caixa no período carregado.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final p in payments) _Line(p.name, formatMoney(p.amount)),
                    const Divider(height: 18),
                    _Line('Total em vendas', formatMoney(detail!.paymentsTotal), emphasize: true),
                  ],
                ),
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.loading, required this.detail, required this.error});

  final bool loading;
  final ClosingDetailDto? detail;
  final String? error;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final count = detail?.salesCount ?? 0;
    final shown = detail?.sales.length ?? 0;
    final title = count == 0
        ? 'VENDAS DESTE CAIXA'
        : 'VENDAS DESTE CAIXA ($count${shown < count ? ' — EXIBINDO $shown' : ''})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (shown == 0)
          Text(
            error ?? 'Nenhuma venda neste caixa.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          _table(detail!.sales),
      ],
    );
  }

  Widget _table(List<ClosingSaleLineDto> sales) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            const _SaleHead(),
            for (final (i, sale) in sales.indexed) ...[
              if (i > 0) Divider(height: 1, color: AppColors.divider),
              _SaleRow(sale),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaleHead extends StatelessWidget {
  const _SaleHead();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final style = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('DATA/HORA', style: style)),
            Expanded(flex: 4, child: Text('CLIENTE', style: style)),
            Expanded(flex: 2, child: Text('NOTA', style: style)),
            Expanded(flex: 2, child: Text('TOTAL', style: style, textAlign: TextAlign.right)),
            Expanded(flex: 2, child: Text('STATUS', style: style, textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow(this.sale);
  final ClosingSaleLineDto sale;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(_stamp(sale.soldAt), style: style)),
          Expanded(flex: 4, child: Text(_document(sale.clientDocument), style: style)),
          Expanded(flex: 2, child: Text(sale.invoiceNumber ?? '—', style: style)),
          Expanded(
            flex: 2,
            child: Text(formatMoney(sale.total), textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: _OkPill(cancelled: sale.cancelled)),
          ),
        ],
      ),
    );
  }
}

class _OkPill extends StatelessWidget {
  const _OkPill({required this.cancelled});
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final fg = cancelled ? AppColors.danger : AppColors.success;
    final bg = cancelled ? AppColors.dangerSoft : AppColors.successSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        cancelled ? 'Cancelada' : 'OK',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.emphasize = false, this.valueColor});

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.text,
                fontSize: 13.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shiftLabel(String? label) {
  if (label == null || label.trim().isEmpty) return 'TURNO';
  final n = int.tryParse(label.trim());
  if (n != null) return '$nº TURNO';
  return label.toUpperCase();
}

String _stamp(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final d = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String _panelDiff(double value) {
  final body = formatMoney(value.abs());
  if (value < 0) return body.replaceFirst('R\$', 'R\$ -');
  if (value > 0) return '+$body';
  return body;
}

String _document(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  if (digits.length == 14) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }
  return raw;
}
