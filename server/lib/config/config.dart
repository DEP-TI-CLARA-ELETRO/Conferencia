import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Configurações da API (banco, porta, seed, etc.).
/// Em vez de espalhar "localhost" e senhas no código, lemos do .env.
class AppConfig {
  AppConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.serverPort,
    required this.corsOrigin,
    required this.sessionTtl,
    required this.migrationsDir,
    required this.seedAdminEmail,
    required this.seedAdminPassword,
    required this.seedDemoUsers,
  });

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int serverPort;
  final String corsOrigin; // quem pode chamar a API do navegador (* = qualquer)
  final Duration sessionTtl; // quanto tempo a sessão vive
  final String migrationsDir; // pasta dos .sql
  final String? seedAdminEmail; // null = não cria admin automático
  final String? seedAdminPassword;
  final bool seedDemoUsers; // true = cria fiscal/tesouraria de exemplo

  /// Lê `server/.env` (se existir) e também as variáveis do sistema operacional.
  factory AppConfig.load() {
    // quiet: true = não grita se faltar arquivo
    final env = DotEnv(includePlatformEnvironment: true, quiet: true);
    // File('.env').existsSync() = o arquivo existe NESTA pasta de trabalho?
    if (File('.env').existsSync()) env.load(['.env']);

    // Função local: pega a chave do env ou usa um valor padrão (fallback)
    String get(String key, String fallback) => env[key] ?? fallback;

    return AppConfig(
      dbHost: get('DB_HOST', 'localhost'),
      dbPort: int.parse(get('DB_PORT', '5432')), // texto -> número
      dbName: get('DB_NAME', 'conferencia'),
      dbUser: get('DB_USER', 'conferencia'),
      dbPassword: get('DB_PASSWORD', 'conferencia_dev'),
      serverPort: int.parse(get('SERVER_PORT', '8080')),
      corsOrigin: get('CORS_ORIGIN', '*'),
      sessionTtl: Duration(hours: int.parse(get('SESSION_TTL_HOURS', '12'))),
      migrationsDir: get('MIGRATIONS_DIR', '../infra/migrations'),
      seedAdminEmail: env['SEED_ADMIN_EMAIL'], // pode ser null
      seedAdminPassword: env['SEED_ADMIN_PASSWORD'],
      // comparação == devolve bool
      seedDemoUsers: get('SEED_DEMO_USERS', 'false') == 'true',
    );
  }
}
