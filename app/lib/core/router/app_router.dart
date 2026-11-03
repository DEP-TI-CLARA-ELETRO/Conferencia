import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_page.dart';
import '../../features/closings/closings_page.dart';
import '../../features/home/home_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/nav_items.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Faz o GoRouter reavaliar o redirect sempre que a sessao mudar.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final loc = state.uri.path;

    switch (auth.status) {
      case AuthStatus.unknown:
        return loc == '/carregando' ? null : '/carregando';
      case AuthStatus.unauthenticated:
        return loc == '/login' ? null : '/login';
      case AuthStatus.authenticated:
        if (loc == '/login' || loc == '/carregando' || loc == '/') return '/inicio';
        final needed = permissionForLocation(loc);
        if (needed != null && !auth.user!.can(needed)) return '/inicio';
        return null;
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
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/inicio', pageBuilder: (_, _) => const NoTransitionPage(child: HomePage())),
          GoRoute(path: '/caixas', pageBuilder: (_, _) => const NoTransitionPage(child: ClosingsPage())),
        ],
      ),
    ],
  );
});
