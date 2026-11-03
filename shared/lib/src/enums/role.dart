/// Perfis do sistema. O [code] e igual ao `roles.code` do banco.
enum Role {
  admin('admin', 'Administrador'),
  fiscal('fiscal', 'Fiscal de Caixa'),
  tesouraria('tesouraria', 'Tesouraria'),
  gerencia('gerencia', 'Gerencia'),
  supervisao('supervisao', 'Supervisao'),
  controladoria('controladoria', 'Controladoria'),
  rh('rh', 'Recursos Humanos'),
  financeiro('financeiro', 'Financeiro');

  const Role(this.code, this.label);

  final String code;
  final String label;

  static Role? fromCode(String code) {
    for (final r in Role.values) {
      if (r.code == code) return r;
    }
    return null;
  }
}
