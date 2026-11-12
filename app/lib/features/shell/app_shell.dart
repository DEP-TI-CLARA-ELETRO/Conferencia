import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../auth/auth_controller.dart';
import 'filter_controls.dart';
import 'group_backdrop.dart';
import 'nav_items.dart';
import 'shell_providers.dart';

const _wideBreakpoint = 900.0;

/// Moldura glass: sidebar flutuante + fundo ambient + top bar translúcida.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.watch(context);
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    final location = GoRouterState.of(context).uri.path;
    final items = navItemsFor(user);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    );

    final collapsed = ref.watch(sidebarCollapsedProvider);
    final body = GroupBackdrop(child: content);

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: GroupBackdrop(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                child: _Sidebar(
                  items: items,
                  location: location,
                  collapsed: collapsed,
                  onToggleCollapse: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(user: user, wide: true),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Builder(
          builder: (context) => _TopBar(
            user: user,
            wide: false,
            onMenu: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: 272,
        backgroundColor: AppColors.sidebar,
        child: _Sidebar(
          items: items,
          location: location,
          closeOnTap: true,
          collapsed: false,
        ),
      ),
      body: body,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.location,
    this.closeOnTap = false,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  final List<NavItem> items;
  final String location;
  final bool closeOnTap;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  static const _expandedWidth = 236.0;
  static const _collapsedWidth = 78.0;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? _collapsedWidth : _expandedWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebar, AppColors.sidebarEnd],
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 160;
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 22, compact ? 12 : 18, 18),
                    child: compact
                        ? const Center(child: _Logo())
                        : const Row(
                            children: [
                              _Logo(),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Conferência',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'MENU',
                        style: TextStyle(
                          color: AppColors.sidebarText.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 12),
                      children: [
                        for (final item in items)
                          _NavTile(
                            item: item,
                            selected: location == item.path || location.startsWith('${item.path}/'),
                            collapsed: compact,
                            onTap: () {
                              if (closeOnTap) Navigator.of(context).pop();
                              context.go(item.path);
                            },
                          ),
                      ],
                    ),
                  ),
                  if (onToggleCollapse != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(compact ? 10 : 12, 8, compact ? 10 : 12, 12),
                      child: _CollapseButton(collapsed: compact, onTap: onToggleCollapse!),
                    ),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Text(
                        'Grupo Clara',
                        style: TextStyle(
                          color: AppColors.sidebarText.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    if (collapsed) {
      return IconButton(
        tooltip: 'Expandir menu',
        onPressed: onTap,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
      );
    }

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        alignment: Alignment.centerLeft,
      ),
      icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 20),
      label: const Text(
        'Recolher menu',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.glowMint.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(Icons.point_of_sale_rounded, color: AppColors.glowMint, size: 18),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 20,
      color: selected ? AppColors.sidebarTextActive : AppColors.sidebarText,
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 12,
            vertical: collapsed ? 12 : 11,
          ),
          alignment: collapsed ? Alignment.center : Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? AppColors.glowMint.withValues(alpha: 0.22) : Colors.transparent,
          ),
          child: collapsed
              ? icon
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.sidebarTextActive : AppColors.sidebarText,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: collapsed
          ? Tooltip(message: item.label, waitDuration: const Duration(milliseconds: 400), child: tile)
          : tile,
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user, required this.wide, this.onMenu});

  final UserDto user;
  final bool wide;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.watch(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 18 : 10, 14, wide ? 18 : 10, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 10),
                  child: Row(
                    children: [
                      if (!wide)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: onMenu,
                        ),
                      const Expanded(child: TopFilterControls()),
                      const SizedBox(width: 4),
                      const ThemeModeButton(),
                      _UserMenu(user: user, showName: wide),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.user, required this.showName});

  final UserDto user;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.watch(context);
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'logout') ref.read(authControllerProvider.notifier).logout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
              Text(user.email, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user.roleLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
