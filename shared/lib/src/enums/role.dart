/// Perfis do sistema (cargos).
///
/// Um [enum] em Dart é uma lista FECHADA de opções possíveis.
/// O [code] é o texto gravado no banco (`roles.code`).
/// O [label] é o texto amigável mostrado na tela.
enum Role {
  // Cada linha é um valor do enum, com dados extras entre parênteses.
  admin('admin', 'Administrador'),
  fiscal('fiscal', 'Fiscal de Caixa'),
  tesouraria('tesouraria', 'Tesouraria'),
  gerencia('gerencia', 'Gerencia'),
  supervisao('supervisao', 'Supervisao'),
  controladoria('controladoria', 'Controladoria'),
  rh('rh', 'Recursos Humanos'),
  financeiro('financeiro', 'Financeiro');

  // Construtor do enum: cada valor acima chama isto com (code, label).
  const Role(this.code, this.label);

  // final = depois de criado, não muda mais.
  final String code; // texto técnico (ex.: "fiscal")
  final String label; // texto para humanos (ex.: "Fiscal de Caixa")

  /// Converte um texto do banco/JSON em um Role.
  /// [static] = chama sem precisar de uma instância: Role.fromCode('admin')
  /// O `?` em Role? significa: pode devolver Role OU null (não achou).
  static Role? fromCode(String code) {
    // Role.values = lista automática com todos os valores do enum.
    for (final r in Role.values) {
      if (r.code == code) return r; // achou: devolve e sai da função
    }
    return null; // não achou nenhum código igual
  }
}

//basicamente, o enum Role é uma lista de cargos do sistema, cada um com um código técnico e um rótulo amigável. Ele também inclui um método estático para converter um código em uma instância de Role, retornando null se o código não corresponder a nenhum cargo definido.