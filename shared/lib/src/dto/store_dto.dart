/// DTO = Data Transfer Object: "ficha" de dados para trafegar entre API e app.
/// Aqui: uma loja (store).
class StoreDto {
  // Construtor com parâmetros NOMEADOS ({ ... }).
  // required = quem cria o objeto É OBRIGADO a passar id, code e name.
  const StoreDto({required this.id, required this.code, required this.name});

  final int id; // número da loja no banco
  final String code; // código curto (ex.: "01")
  final String name; // nome (ex.: "Loja 01 - Centro")

  /// factory = construtor alternativo que MONTA o objeto a partir de outra coisa.
  /// Aqui: a partir de um Map (o JSON já decodificado).
  ///
  /// json['id'] as int = "pegue a chave id e trate como inteiro".
  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
      );

  /// Converte este objeto Dart de volta para um Map (que vira JSON na rede).
  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};
}
