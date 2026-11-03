/// Etapas pelas quais um caixa fechado passa ate ser finalizado.
enum ClosingStage {
  pdvImported('pdv_imported', 'PDV importado'),
  fiscal('fiscal', 'Conferencia fiscal'),
  treasury('treasury', 'Tesouraria'),
  manager('manager', 'Gerencia'),
  supervisor('supervisor', 'Supervisao'),
  audit('audit', 'Controladoria'),
  done('done', 'Finalizado');

  const ClosingStage(this.code, this.label);

  final String code;
  final String label;

  static ClosingStage? fromCode(String code) {
    for (final s in ClosingStage.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}
