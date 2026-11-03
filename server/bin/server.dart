// Ponto de entrada da API.
// Rodar com: dart run bin/server.dart  (de dentro da pasta server/)

import 'dart:io'; // stdout, ProcessSignal, exit, InternetAddress

import 'package:server/app_server.dart';
import 'package:server/config/config.dart';
import 'package:server/db/database.dart';
import 'package:server/db/migrator.dart';
import 'package:server/modules/auth/auth_repository.dart';
import 'package:server/seed/dev_seed.dart';
import 'package:shelf/shelf_io.dart' as io; // "as io" = apelido para não misturar nomes

/// main = função que o Dart executa primeiro.
/// `Future` + `async` = esta função faz coisas demoradas (rede/banco) e espera.
Future<void> main() async {
  // 1) Lê .env e variáveis de ambiente
  final config = AppConfig.load();

  // 2) Abre um "pool" de conexões com o PostgreSQL
  final db = createPool(config);

  // 3) Aplica migrations SQL que ainda não rodaram
  await runMigrations(db, config.migrationsDir);

  // 4) Prepara o repositório de autenticação e cria o admin de desenvolvimento
  final authRepo = AuthRepository(db);
  await seedAdmin(authRepo, config);

  // 5) Sobe o servidor HTTP escutando em todas as interfaces (0.0.0.0) na porta configurada
  final server = await io.serve(
    buildHandler(config, db, authRepo), // o "roteador" de pedidos HTTP
    InternetAddress.anyIPv4,
    config.serverPort,
  );
  stdout.writeln('API em http://localhost:${server.port}');

  // 6) Quando apertar Ctrl+C, fecha o servidor e o banco com educação
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    await db.close();
    exit(0); // encerra o processo com código 0 (sucesso)
  });
}
