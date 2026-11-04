import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_controller.dart';
import '../shell/shell_providers.dart';
import 'closings_repository.dart';

final closingsRepositoryProvider = Provider<ClosingsRepository>(
  (ref) => ClosingsRepository(ref.watch(apiClientProvider)),
);

class ClosingsUiState {
  const ClosingsUiState({
    this.items = const [],
    this.loading = false,
    this.syncing = false,
    this.webpostoReady = false,
    this.error,
    this.syncMessage,
  });

  final List<ClosingDto> items;
  final bool loading;
  final bool syncing;
  final bool webpostoReady;
  final String? error;
  final String? syncMessage;
}

final closingsControllerProvider =
    NotifierProvider<ClosingsController, ClosingsUiState>(ClosingsController.new);

class ClosingsController extends Notifier<ClosingsUiState> {
  @override
  ClosingsUiState build() {
    ref.listen(selectedDateProvider, (_, _) => load());
    ref.listen(selectedStoreIdProvider, (_, _) => load());
    Future.microtask(load);
    return const ClosingsUiState(loading: true);
  }

  ClosingsRepository get _repo => ref.read(closingsRepositoryProvider);

  Future<void> load() async {
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) return;

    state = ClosingsUiState(
      items: state.items,
      loading: true,
      webpostoReady: state.webpostoReady,
    );
    try {
      final date = ref.read(selectedDateProvider);
      // Lista todos os caixas do dia (postos syncados); filtro por loja pode voltar depois.
      final configured = await _repo.webpostoConfigured();
      final items = await _repo.list(date: date);
      state = ClosingsUiState(
        items: items,
        webpostoReady: configured,
      );
    } on ApiException catch (e) {
      state = ClosingsUiState(error: e.message, webpostoReady: state.webpostoReady);
    }
  }

  Future<void> syncWebposto() async {
    state = ClosingsUiState(
      items: state.items,
      syncing: true,
      webpostoReady: state.webpostoReady,
    );
    try {
      final date = ref.read(selectedDateProvider);
      final result = await _repo.syncWebposto(date: date);
      await load();
      state = ClosingsUiState(
        items: state.items,
        webpostoReady: true,
        syncMessage:
            'Sincronizado: ${result.companiesUpserted} postos, ${result.closingsUpserted} caixas (${result.from}).',
      );
    } on ApiException catch (e) {
      state = ClosingsUiState(
        items: state.items,
        webpostoReady: state.webpostoReady,
        error: e.message,
      );
    }
  }
}
