import 'package:postgres/postgres.dart';

import '../config/config.dart';

/// Cria um Pool: várias conexões reutilizáveis com o PostgreSQL.
/// Assim cada request HTTP não precisa abrir/fechar o banco do zero.
Pool<void> createPool(AppConfig c) {
  return Pool.withEndpoints(
    [
      // Endpoint = "endereço" do banco (host, porta, nome, usuário, senha)
      Endpoint(
        host: c.dbHost,
        port: c.dbPort,
        database: c.dbName,
        username: c.dbUser,
        password: c.dbPassword,
      ),
    ],
    settings: const PoolSettings(
      maxConnectionCount: 10, // no máximo 10 conexões ao mesmo tempo
      sslMode: SslMode.disable, // em desenvolvimento local sem HTTPS no Postgres
    ),
  );
}
