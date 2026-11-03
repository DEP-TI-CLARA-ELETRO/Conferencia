import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_page.dart';
import '../../features/closings/closings_page.dart';
import '../../features/home/home_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/nav_items.dart';

/// Provider que cria o GoRouter (mapa de URLs do app).
final routerProvider = Provider<GoRouter>((ref) {
  // ValueNotifier: quando muda, o GoRouter reavalia o redirect
  final refresh = ValueNotifier<int>(0);
  // Sempre que AuthState mudar, incrementa refresh -> redirect roda de novo
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose); // limpa ao destruir o provider

  /// Porteiro: decide se a URL pedida pode ser mostrada.
  /// return null = pode ficar; return '/algo' = redireciona.
  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final loc = state.uri.path; // caminho atual (ex.: /caixas)

    switch (auth.status) {
      case AuthStatus.unknown:
        // Ainda checando token salvo
        return loc == '/carregando' ? null : '/carregando';
      case AuthStatus.unauthenticated:
        // Sem login: só pode ver /login
        return loc == '/login' ? null : '/login';
      case AuthStatus.authenticated:
        // Já logado: não fica em login/carregando
        if (loc == '/login' || loc == '/carregando' || loc == '/') return '/inicio';
        // Checa permissão da página
        final needed = permissionForLocation(loc);
        if (needed != null && !auth.user!.can(needed)) return '/inicio';
        return null; // ok
    }
  }

  return GoRouter(
    initialLocation: '/carregando',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/carregando',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      // ShellRoute = moldura fixa (menu) + child que troca
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          // NoTransitionPage = troca de aba sem animação de slide
          GoRoute(path: '/inicio', pageBuilder: (_, _) => const NoTransitionPage(child: HomePage())),
          GoRoute(path: '/caixas', pageBuilder: (_, _) => const NoTransitionPage(child: ClosingsPage())),
        ],
      ),
    ],
  );
});
