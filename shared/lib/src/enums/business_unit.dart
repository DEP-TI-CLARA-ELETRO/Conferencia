/// Grupo de negócio da loja (postos, mercados, etc.).
enum BusinessUnit {
  posto,
  mercado,
  materiais,
  presentes,
  distribuicao,
  outros;

  String get code => name;

  String get label => switch (this) {
        BusinessUnit.posto => 'Postos',
        BusinessUnit.mercado => 'Supermercados',
        BusinessUnit.materiais => 'Materiais de construção',
        BusinessUnit.presentes => 'Presentes',
        BusinessUnit.distribuicao => 'Distribuição',
        BusinessUnit.outros => 'Outros',
      };

  String get shortLabel => switch (this) {
        BusinessUnit.posto => 'Postos',
        BusinessUnit.mercado => 'Mercados',
        BusinessUnit.materiais => 'Materiais',
        BusinessUnit.presentes => 'Presentes',
        BusinessUnit.distribuicao => 'Distribuição',
        BusinessUnit.outros => 'Outros',
      };

  static BusinessUnit fromCode(String? code) {
    if (code == null || code.isEmpty) return BusinessUnit.outros;
    final normalized = code.trim().toLowerCase();
    return BusinessUnit.values.firstWhere(
      (u) => u.code == normalized,
      orElse: () => BusinessUnit.outros,
    );
  }
}
