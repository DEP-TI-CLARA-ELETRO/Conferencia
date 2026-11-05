import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../auth/auth_controller.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Intervalo de datas do filtro (início e fim inclusivos).
class DateRangeSelection {
  const DateRangeSelection({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  bool get isSingleDay => from == to;
}

final selectedDateRangeProvider =
    NotifierProvider<SelectedDateRange, DateRangeSelection>(SelectedDateRange.new);

class SelectedDateRange extends Notifier<DateRangeSelection> {
  @override
  DateRangeSelection build() {
    final today = _dayOnly(DateTime.now());
    return DateRangeSelection(from: today, to: today);
  }

  void selectRange(DateTime from, DateTime to) {
    final a = _dayOnly(from);
    final b = _dayOnly(to);
    state = DateRangeSelection(
      from: a.isBefore(b) ? a : b,
      to: a.isBefore(b) ? b : a,
    );
  }

  void selectDay(DateTime day) {
    final d = _dayOnly(day);
    state = DateRangeSelection(from: d, to: d);
  }
}

/// Compat: data "principal" (fim do intervalo) — usada no Início.
final selectedDateProvider = Provider<DateTime>((ref) {
  return ref.watch(selectedDateRangeProvider).to;
});

/// Grupo de negócio (null = todos).
final selectedBusinessUnitProvider =
    NotifierProvider<SelectedBusinessUnit, BusinessUnit?>(SelectedBusinessUnit.new);

class SelectedBusinessUnit extends Notifier<BusinessUnit?> {
  @override
  BusinessUnit? build() => null;

  void select(BusinessUnit? unit) {
    state = unit;
    // Ao trocar o grupo, limpa loja específica.
    ref.read(selectedStoreIdProvider.notifier).clear();
  }
}

/// Loja selecionada (null = todas do grupo / todas).
final selectedStoreIdProvider =
    NotifierProvider<SelectedStoreId, int?>(SelectedStoreId.new);

class SelectedStoreId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
  void clear() => state = null;
}

/// Lojas do usuário filtradas pelo grupo atual.
final filteredStoresProvider = Provider<List<StoreDto>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  final unit = ref.watch(selectedBusinessUnitProvider);
  final stores = user?.stores ?? const <StoreDto>[];
  if (unit == null) return stores;
  return stores.where((s) => s.businessUnit == unit).toList();
});

/// Grupos presentes nas lojas do usuário (só os que existem).
final availableBusinessUnitsProvider = Provider<List<BusinessUnit>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  final stores = user?.stores ?? const <StoreDto>[];
  final set = <BusinessUnit>{};
  for (final s in stores) {
    set.add(s.businessUnit);
  }
  // Ordem fixa do enum
  return BusinessUnit.values.where(set.contains).toList();
});

final selectedStoreProvider = Provider<StoreDto?>((ref) {
  final id = ref.watch(selectedStoreIdProvider);
  if (id == null) return null;
  final stores = ref.watch(filteredStoresProvider);
  for (final s in stores) {
    if (s.id == id) return s;
  }
  final all = ref.watch(authControllerProvider).user?.stores ?? const <StoreDto>[];
  for (final s in all) {
    if (s.id == id) return s;
  }
  return null;
});

/// Sidebar desktop recolhida (só ícones) ou expandida.
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsed, bool>(SidebarCollapsed.new);

class SidebarCollapsed extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
