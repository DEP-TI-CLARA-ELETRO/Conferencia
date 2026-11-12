import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'closings_repository.dart';

const _paymentLabels = {
  'dinheiro': 'Dinheiro',
  'notaPrazo': 'Notas a prazo',
  'cheque': 'Cheque',
  'chequePre': 'Cheque pré',
  'cartao': 'Cartão',
  'cartaFrete': 'Carta frete',
  'valeCliente': 'Vale cliente',
  'emprestimo': 'Empréstimo',
  'prePag': 'Pré-pagamento',
  'despesa': 'Despesa',
  'valeFun': 'Vale funcionário',
  'chequePagar': 'Cheque a pagar',
  'transfBanc': 'Transferência bancária',
  'transfDeb': 'Transferência débito',
  'fundoCxDeb': 'Fundo de caixa débito',
};

/// Seção de cupons no painel do caixa: listar, capturar, revisar e confirmar.
class ClosingCouponPanel extends StatefulWidget {
  const ClosingCouponPanel({
    super.key,
    required this.closing,
    required this.repository,
  });

  final ClosingDto closing;
  final ClosingsRepository repository;

  @override
  State<ClosingCouponPanel> createState() => _ClosingCouponPanelState();
}

class _ClosingCouponPanelState extends State<ClosingCouponPanel> {
  final _picker = ImagePicker();
  List<ClosingCouponDto> _items = [];
  var _loading = true;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.listCoupons(widget.closing.id);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2200,
      );
      if (file == null) return;
      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      final name = file.name.isEmpty ? 'cupom.jpg' : file.name;
      final coupon = await widget.repository.uploadCoupon(
        closingId: widget.closing.id,
        bytes: bytes,
        filename: name,
        contentType: _contentType(name),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _reload();
      if (!mounted) return;
      await _openReview(coupon);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _openReview(ClosingCouponDto coupon) async {
    final updated = await showDialog<ClosingCouponDto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CouponReviewDialog(
        closing: widget.closing,
        coupon: coupon,
        repository: widget.repository,
      ),
    );
    if (updated != null) await _reload();
  }

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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CUPOM DE FECHAMENTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Fotografe ou anexe o cupom. A leitura é revisada e cruzada com o ERP.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!kIsWeb)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Fotografar'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(kIsWeb ? 'Enviar imagem' : 'Galeria'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_items.isEmpty)
              Text(
                'Nenhum cupom anexado neste caixa.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              )
            else
              for (final c in _items) ...[
                _CouponTile(
                  coupon: c,
                  onOpen: () => _openReview(c),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.coupon, required this.onOpen});

  final ClosingCouponDto coupon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final match = coupon.matchResult;
    final statusColor = switch (coupon.status) {
      'confirmed' when match?.ok == true => AppColors.success,
      'confirmed' => AppColors.danger,
      'failed' => AppColors.danger,
      'ocr_ready' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final statusLabel = switch (coupon.status) {
      'confirmed' when match?.ok == true => 'Confirmado · bateu',
      'confirmed' => 'Confirmado · divergente',
      'failed' => 'Falha na leitura',
      'ocr_ready' => 'Aguardando confirmação',
      'ocr_pending' => 'Lendo…',
      _ => coupon.status,
    };

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.originalFilename ?? 'Cupom',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponReviewDialog extends StatefulWidget {
  const _CouponReviewDialog({
    required this.closing,
    required this.coupon,
    required this.repository,
  });

  final ClosingDto closing;
  final ClosingCouponDto coupon;
  final ClosingsRepository repository;

  @override
  State<_CouponReviewDialog> createState() => _CouponReviewDialogState();
}

class _CouponReviewDialogState extends State<_CouponReviewDialog> {
  late Map<String, TextEditingController> _controllers;
  late Set<String> _divergingKeys;
  var _saving = false;
  String? _error;
  ClosingCouponDto? _confirmed;

  @override
  void initState() {
    super.initState();
    _divergingKeys = _enginesDisagree(widget.coupon.ocrRuns);
    final seed = widget.coupon.confirmedValues?.amounts.isNotEmpty == true
        ? widget.coupon.confirmedValues!.amounts
        : widget.coupon.proposedValues.amounts;
    final keys = {
      ...seed.keys,
      ...widget.closing.paymentBreakdown.keys,
      'dinheiro',
      'cartao',
      'notaPrazo',
    };
    _controllers = {
      for (final k in keys)
        k: TextEditingController(
          text: seed[k] == null ? '' : seed[k]!.toStringAsFixed(2).replaceAll('.', ','),
        ),
    };
  }

  Set<String> _enginesDisagree(List<CouponOcrRunDto> runs) {
    final byEngine = {
      for (final r in runs)
        if (r.error == null && r.parsed.isNotEmpty) r.engine: r.parsed,
    };
    if (byEngine.length < 2) return {};
    final a = byEngine.values.first;
    final b = byEngine.values.elementAt(1);
    final keys = {...a.keys, ...b.keys};
    return {
      for (final k in keys)
        if (a[k] != null && b[k] != null && (a[k]! - b[k]!).abs() >= 0.015) k,
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> _readValues() {
    final out = <String, double>{};
    for (final e in _controllers.entries) {
      final raw = e.value.text.trim();
      if (raw.isEmpty) continue;
      final normalized = raw.contains(',')
          ? raw.replaceAll('.', '').replaceAll(',', '.')
          : raw;
      final n = double.tryParse(normalized);
      if (n != null) out[e.key] = n;
    }
    return out;
  }

  Future<void> _confirm() async {
    final values = _readValues();
    if (values.isEmpty) {
      setState(() => _error = 'Informe ao menos um valor.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.confirmCoupon(
        closingId: widget.closing.id,
        couponId: widget.coupon.id,
        values: values,
      );
      if (!mounted) return;
      setState(() {
        _confirmed = updated;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final coupon = _confirmed ?? widget.coupon;
    final match = coupon.matchResult;

    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revisar cupom',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, _confirmed),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (widget.coupon.ocrWarning != null) ...[
                Text(
                  widget.coupon.ocrWarning!,
                  style: TextStyle(color: AppColors.warning, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Confira os valores lidos. Só depois da confirmação o sistema cruza com o ERP.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final key in _controllers.keys)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: _controllers[key],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: _confirmed == null,
                          decoration: InputDecoration(
                            labelText: _paymentLabels[key] ?? key,
                            prefixText: 'R\$ ',
                            helperText: _divergingKeys.contains(key)
                                ? 'Motores OCR divergiram neste valor'
                                : null,
                            helperStyle: TextStyle(color: AppColors.warning, fontSize: 11),
                            filled: _divergingKeys.contains(key),
                            fillColor: _divergingKeys.contains(key)
                                ? AppColors.warningSoft
                                : null,
                          ),
                        ),
                      ),
                    if (match != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        match.ok ? 'Resultado: bateu com o ERP' : 'Resultado: há divergências',
                        style: TextStyle(
                          color: match.ok ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final line in match.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line.label,
                                  style: TextStyle(
                                    color: line.ok ? AppColors.text : AppColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                'ERP ${line.expected == null ? '—' : formatMoney(line.expected!)}',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Cupom ${line.scanned == null ? '—' : formatMoney(line.scanned!)}',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      if (match.totalDiff != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Diferença total: ${formatDiff(match.totalDiff!)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: match.totalDiff!.abs() < 0.015
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                const SizedBox(height: 8),
              ],
              if (_confirmed == null)
                FilledButton(
                  onPressed: _saving ? null : _confirm,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar e cruzar com ERP'),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.pop(context, _confirmed),
                  child: const Text('Fechar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
