import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../auth/auth_controller.dart';

/// Loja selecionada na barra superior (padrao: primeira acessivel).
final selectedStoreIdProvider = NotifierProvider<SelectedStoreId, int?>(SelectedStoreId.new);

class SelectedStoreId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int id) => state = id;
}

final selectedStoreProvider = Provider<StoreDto?>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.stores.isEmpty) return null;
  final id = ref.watch(selectedStoreIdProvider);
  return user.stores.firstWhere((s) => s.id == id, orElse: () => user.stores.first);
});

/// Data de trabalho selecionada na barra superior.
final selectedDateProvider = NotifierProvider<SelectedDate, DateTime>(SelectedDate.new);

class SelectedDate extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void select(DateTime d) => state = DateTime(d.year, d.month, d.day);
}
