/// Permissoes do sistema. O [code] e igual ao `permissions.code` do banco.
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

  const Permission(this.code);

  final String code;

  static Permission? fromCode(String code) {
    for (final p in Permission.values) {
      if (p.code == code) return p;
    }
    return null;
  }
}
