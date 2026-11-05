// Este arquivo é a "porta de entrada" do pacote shared.
// Quem faz `import 'package:shared/shared.dart'` enxerga tudo o que exportamos abaixo.
//
// library; = declara este arquivo como biblioteca Dart (organização do pacote).
library;

// export = "repassa" os arquivos internos para quem importa o pacote.
// Assim app e server não precisam conhecer a pasta src/ por dentro.
export 'src/enums/business_unit.dart';
export 'src/enums/closing_stage.dart';
export 'src/enums/permission.dart';
export 'src/enums/role.dart';
export 'src/dto/store_dto.dart';
export 'src/dto/user_dto.dart';
export 'src/dto/session_dto.dart';
export 'src/dto/closing_dto.dart';
