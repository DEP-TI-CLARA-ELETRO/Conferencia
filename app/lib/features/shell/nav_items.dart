import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Um item do menu lateral (rota + texto + ícones + permissão necessária).
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.permission,
  });

  final String path; // ex.: '/inicio'
  final String label; // ex.: 'Início'
  final IconData icon; // ícone quando NÃO selecionado
  final IconData selectedIcon; // ícone quando selecionado
  final Permission permission; // sem essa permissão, o item some
}

/// Catálogo de itens do menu.
/// Novos módulos: adicione aqui E em app_router.dart.
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

/// Filtra o menu: só itens que o usuário.can(permissão).
List<NavItem> navItemsFor(UserDto user) =>
    navItems.where((e) => user.can(e.permission)).toList();

/// Qual permissão a URL exige? null = livre (dentro do autenticado).
Permission? permissionForLocation(String location) {
  for (final item in navItems) {
    // casa exatamente ou é subcaminho (/caixas/123)
    if (location == item.path || location.startsWith('${item.path}/')) {
      return item.permission;
    }
  }
  return null;
}
