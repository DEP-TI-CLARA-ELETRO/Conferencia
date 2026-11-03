import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../auth/auth_controller.dart';

/// ID da loja selecionada na barra superior (null = ainda não escolheu).
final selectedStoreIdProvider =
    NotifierProvider<SelectedStoreId, int?>(SelectedStoreId.new);

class SelectedStoreId extends Notifier<int?> {
  @override
  int? build() => null; // estado inicial

  void select(int id) => state = id; // atualiza o estado
}

/// Loja selecionada como objeto StoreDto (derivada do id + lista do usuário).
final selectedStoreProvider = Provider<StoreDto?>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.stores.isEmpty) return null;
  final id = ref.watch(selectedStoreIdProvider);
  // Se o id não existir na lista, pega a primeira loja
  return user.stores.firstWhere(
    (s) => s.id == id,
    orElse: () => user.stores.first,
  );
});

/// Data de trabalho selecionada (só dia/mês/ano, sem hora).
final selectedDateProvider =
    NotifierProvider<SelectedDate, DateTime>(SelectedDate.new);

class SelectedDate extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day); // zera hora/minuto/segundo
  }

  void select(DateTime d) => state = DateTime(d.year, d.month, d.day);
}
