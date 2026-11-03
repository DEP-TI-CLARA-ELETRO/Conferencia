/// Permissões do sistema (o que cada perfil PODE fazer).
///
/// Exemplo: Permission.closingsView.code == "closings.view"
/// Esse texto é o mesmo da tabela `permissions` no PostgreSQL.
enum Permission {
  homeView('home.view'),
  closingsView('closings.view'),
  closingsFiscal('closings.fiscal'),
  closingsTreasury('closings.treasury'),
  closingsManager('closings.manager'),
  closingsSupervisor('closings.supervisor'),
  closingsAudit('closings.audit'),
  vouchersView('vouchers.view'),
  hrView('hr.view'),
  financeView('finance.view'),
  usersManage('users.manage');

  // Cada permissão só carrega o código (string).
  const Permission(this.code);

  final String code;

  /// Traduz "closings.view" (vindo do JSON) em Permission.closingsView.
  static Permission? fromCode(String code) {
    for (final p in Permission.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}
