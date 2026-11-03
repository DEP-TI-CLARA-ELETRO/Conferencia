import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../auth/auth_controller.dart';
import 'nav_items.dart';
import 'shell_providers.dart';

/// A partir desta largura (px), mostramos sidebar fixa; abaixo, menu gaveta.
const _wideBreakpoint = 900.0;

/// Moldura do app logado: menu + barra superior + miolo (child).
/// O child é HomePage ou ClosingsPage, trocado pelo go_router.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    // Sem usuário não deveria chegar aqui (router manda para login)
    if (user == null) return const SizedBox.shrink();

    final location = GoRouterState.of(context).uri.path; // URL atual
    final items = navItemsFor(user); // menu filtrado por permissão
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    // Conteúdo centralizado com largura máxima (não estica infinito em TV/ultrawide)
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: child,
      ),
    );

    // ----- LAYOUT DESKTOP: sidebar | conteúdo -----
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(items: items, location: location),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(user: user, wide: true),
                  const Divider(height: 1),
                  Expanded(child: content), // miolo cresce
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ----- LAYOUT MOBILE: AppBar + Drawer -----
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Builder(
          // Builder cria um context "filho" que enxerga o Scaffold
          builder: (context) => _TopBar(
            user: user,
            wide: false,
            onMenu: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: 260,
        child: _Sidebar(items: items, location: location, closeOnTap: true),
      ),
      body: content,
    );
  }
}

/// Menu lateral (lista de NavItem).
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.location, this.closeOnTap = false});

  final List<NavItem> items;
  final String location;
  final bool closeOnTap; // no drawer: fecha ao tocar

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Colors.white,
      child: SafeArea(
        // SafeArea evita notch/status bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: Row(
                children: [
                  _Logo(),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Conferência',
                      overflow: TextOverflow.ellipsis, // corta com ...
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // collection-for: um tile por item
                  for (final item in items)
                    _NavTile(
                      item: item,
                      selected: location == item.path || location.startsWith('${item.path}/'),
                      onTap: () {
                        if (closeOnTap) Navigator.of(context).pop(); // fecha drawer
                        context.go(item.path); // navega (go_router)
                      },
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
      child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 18),
    );
  }
}

/// Uma linha do menu.
class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(selected ? item.selectedIcon : item.icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra superior: loja, data, usuário.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user, required this.wide, this.onMenu});

  final UserDto user;
  final bool wide;
  final VoidCallback? onMenu; // só no mobile (abre drawer)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(selectedStoreProvider);
    final date = ref.watch(selectedDateProvider);

    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 12),
            child: Row(
              children: [
                if (!wide) IconButton(icon: const Icon(Icons.menu_rounded), onPressed: onMenu),
                if (store != null) _StorePicker(user: user, current: store),
                const SizedBox(width: 8),
                _DatePill(date: date),
                const Spacer(), // empurra o que vem depois para a direita
                _UserMenu(user: user, showName: wide),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pílula visual reutilizada (ícone + texto).
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seletor de loja (menu se houver 2+ lojas).
class _StorePicker extends ConsumerWidget {
  const _StorePicker({required this.user, required this.current});

  final UserDto user;
  final StoreDto current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pill = _Pill(icon: Icons.storefront_outlined, label: current.name);
    if (user.stores.length < 2) return Flexible(child: pill); // só mostra, sem menu

    return Flexible(
      child: PopupMenuButton<int>(
        tooltip: 'Trocar de loja',
        onSelected: (id) => ref.read(selectedStoreIdProvider.notifier).select(id),
        itemBuilder: (_) => [
          for (final s in user.stores) PopupMenuItem(value: s.id, child: Text(s.name)),
        ],
        child: pill, // o que aparece fechado
      ),
    );
  }
}

/// Pílula de data: toque abre o calendário.
class _DatePill extends ConsumerWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        // Usuário pode cancelar → picked fica null
        if (picked != null) ref.read(selectedDateProvider.notifier).select(picked);
      },
      child: _Pill(icon: Icons.calendar_today_outlined, label: formatDate(date)),
    );
  }
}

/// Avatar + menu Sair.
class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.user, required this.showName});

  final UserDto user;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      offset: const Offset(0, 48), // abre um pouco abaixo
      onSelected: (v) {
        if (v == 'logout') ref.read(authControllerProvider.notifier).logout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false, // só informativo (não clicável)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
              Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: 10),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(user.roleLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              user.initials,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
