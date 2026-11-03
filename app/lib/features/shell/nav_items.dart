import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.permission,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Permission permission;
}

/// Itens do menu lateral. Cada um so aparece para quem tem a permissao.
/// Novos modulos entram aqui e em `app_router.dart`.
const navItems = <NavItem>[
  NavItem(
    path: '/inicio',
    label: 'Início',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    permission: Permission.homeView,
  ),
  NavItem(
    path: '/caixas',
    label: 'Caixas do dia',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    permission: Permission.closingsView,
  ),
];

List<NavItem> navItemsFor(UserDto user) =>
    navItems.where((e) => user.can(e.permission)).toList();

/// Permissao exigida para abrir [location], ou null se livre.
Permission? permissionForLocation(String location) {
  for (final item in navItems) {
    if (location == item.path || location.startsWith('${item.path}/')) {
      return item.permission;
    }
  }
  return null;
}
