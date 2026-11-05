import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'shell_providers.dart';

/// Controles compactos da barra superior: grupo, loja e período.
class TopFilterControls extends ConsumerWidget {
  const TopFilterControls({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(selectedBusinessUnitProvider);
    final store = ref.watch(selectedStoreProvider);
    final range = ref.watch(selectedDateRangeProvider);
    final units = ref.watch(availableBusinessUnitsProvider);

    final storeLabel = store?.name ??
        (unit == null ? 'Todas as lojas' : 'Todas · ${unit.shortLabel}');

    return Row(
      children: [
        Flexible(
          child: _MenuPill<String>(
            icon: Icons.category_outlined,
            label: unit?.shortLabel ?? 'Todos os grupos',
            menuBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'all',
                child: _CheckedItem(
                  checked: unit == null,
                  label: 'Todos os grupos',
                ),
              ),
              const PopupMenuDivider(),
              for (final u in units)
                PopupMenuItem<String>(
                  value: u.code,
                  child: _CheckedItem(
                    checked: unit == u,
                    label: u.label,
                  ),
                ),
            ],
            onSelected: (value) {
              ref.read(selectedBusinessUnitProvider.notifier).select(
                    value == 'all' ? null : BusinessUnit.fromCode(value),
                  );
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: compact ? 1 : 2,
          child: _TapPill(
            icon: Icons.storefront_outlined,
            label: storeLabel,
            onTap: () => _openStorePicker(context, ref),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _TapPill(
            icon: Icons.date_range_rounded,
            label: formatDateRange(range.from, range.to),
            onTap: () => _openPeriodPicker(context, ref, range),
          ),
        ),
      ],
    );
  }

  Future<void> _openStorePicker(BuildContext context, WidgetRef ref) async {
    final stores = ref.read(filteredStoresProvider);
    final selectedId = ref.read(selectedStoreIdProvider);
    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => _StorePickerDialog(stores: stores, selectedId: selectedId),
    );
    if (result == null) return;
    if (result == 'all') {
      ref.read(selectedStoreIdProvider.notifier).clear();
    } else if (result is int) {
      ref.read(selectedStoreIdProvider.notifier).select(result);
    }
  }

  Future<void> _openPeriodPicker(
    BuildContext context,
    WidgetRef ref,
    DateRangeSelection range,
  ) async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => _PeriodPickerDialog(initial: range),
    );
    if (picked != null) {
      ref.read(selectedDateRangeProvider.notifier).selectRange(
            picked.start,
            picked.end,
          );
    }
  }
}

class _CheckedItem extends StatelessWidget {
  const _CheckedItem({required this.checked, required this.label});

  final bool checked;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: checked ? AppColors.primary : AppColors.textTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    required this.icon,
    required this.label,
    required this.menuBuilder,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final List<PopupMenuEntry<T>> Function(BuildContext context) menuBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: menuBuilder,
      child: _PillShell(icon: icon, label: label),
    );
  }
}

class _TapPill extends StatelessWidget {
  const _TapPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: _PillShell(icon: icon, label: label),
    );
  }
}

class _PillShell extends StatelessWidget {
  const _PillShell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

/// Diálogo central (melhor no desktop/web que bottom sheet).
class _StorePickerDialog extends StatefulWidget {
  const _StorePickerDialog({required this.stores, required this.selectedId});

  final List<StoreDto> stores;
  final int? selectedId;

  @override
  State<_StorePickerDialog> createState() => _StorePickerDialogState();
}

class _StorePickerDialogState extends State<_StorePickerDialog> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.stores
        : widget.stores
            .where(
              (s) =>
                  s.name.toLowerCase().contains(q) ||
                  s.code.toLowerCase().contains(q) ||
                  s.businessUnit.label.toLowerCase().contains(q),
            )
            .toList();

    final grouped = <BusinessUnit, List<StoreDto>>{};
    for (final s in filtered) {
      grouped.putIfAbsent(s.businessUnit, () => []).add(s);
    }
    final units = BusinessUnit.values.where(grouped.containsKey).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Selecionar loja',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome ou código…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.selectedId == null ? Icons.check_circle : Icons.circle_outlined,
                  color: widget.selectedId == null ? AppColors.primary : AppColors.textTertiary,
                ),
                title: const Text(
                  'Todas as lojas do filtro',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, 'all'),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma loja neste grupo',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: units.length,
                        itemBuilder: (context, i) {
                          final unit = units[i];
                          final list = grouped[unit]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                                child: Text(
                                  unit.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              for (final s in list)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    widget.selectedId == s.id
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: widget.selectedId == s.id
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                  title: Text(
                                    s.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text('${s.code} · ${s.businessUnit.shortLabel}'),
                                  onTap: () => Navigator.pop(context, s.id),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Período com atalhos claros + datas De/Até.
class _PeriodPickerDialog extends StatefulWidget {
  const _PeriodPickerDialog({required this.initial});

  final DateRangeSelection initial;

  @override
  State<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<_PeriodPickerDialog> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initial.from;
    _to = widget.initial.to;
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _applyPreset(DateTime from, DateTime to) {
    setState(() {
      _from = from;
      _to = to;
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
      helpText: 'Data inicial',
    );
    if (picked != null) setState(() => _from = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to.isBefore(_from) ? _from : _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Data final',
    );
    if (picked != null) setState(() => _to = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final yesterday = today.subtract(const Duration(days: 1));
    final last7 = today.subtract(const Duration(days: 6));
    final monthStart = DateTime(today.year, today.month, 1);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Período',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Escolha um atalho ou as datas De / Até',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(
                    label: 'Hoje',
                    selected: _from == today && _to == today,
                    onTap: () => _applyPreset(today, today),
                  ),
                  _PresetChip(
                    label: 'Ontem',
                    selected: _from == yesterday && _to == yesterday,
                    onTap: () => _applyPreset(yesterday, yesterday),
                  ),
                  _PresetChip(
                    label: 'Últimos 7 dias',
                    selected: _from == last7 && _to == today,
                    onTap: () => _applyPreset(last7, today),
                  ),
                  _PresetChip(
                    label: 'Este mês',
                    selected: _from == monthStart && _to == today,
                    onTap: () => _applyPreset(monthStart, today),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DateBox(
                      caption: 'De',
                      value: formatDate(_from),
                      onTap: _pickFrom,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textTertiary),
                  ),
                  Expanded(
                    child: _DateBox(
                      caption: 'Até',
                      value: formatDate(_to),
                      onTap: _pickTo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        DateTimeRange(start: _from, end: _to),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.caption,
    required this.value,
    required this.onTap,
  });

  final String caption;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
