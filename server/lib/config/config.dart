import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Configurações da API (banco, porta, seed, WebPosto, etc.).
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
    required this.webpostoBaseUrl,
    required this.webpostoChave,
  });

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int serverPort;
  final String corsOrigin;
  final Duration sessionTtl;
  final String migrationsDir;
  final String? seedAdminEmail;
  final String? seedAdminPassword;
  final bool seedDemoUsers;

  /// URL base do WebPosto (sem barra no final).
  final String webpostoBaseUrl;

  /// Chave de integração (?chave=...). Vazia = sync desabilitado.
  final String webpostoChave;

  bool get webpostoConfigured => webpostoChave.trim().isNotEmpty;

  factory AppConfig.load() {
    final env = DotEnv(includePlatformEnvironment: true, quiet: true);
    if (File('.env').existsSync()) env.load(['.env']);

    String get(String key, String fallback) => env[key] ?? fallback;

    return AppConfig(
      dbHost: get('DB_HOST', 'localhost'),
      dbPort: int.parse(get('DB_PORT', '5432')),
      dbName: get('DB_NAME', 'conferencia'),
      dbUser: get('DB_USER', 'conferencia'),
      dbPassword: get('DB_PASSWORD', 'conferencia_dev'),
      serverPort: int.parse(get('SERVER_PORT', '8080')),
      corsOrigin: get('CORS_ORIGIN', '*'),
      sessionTtl: Duration(hours: int.parse(get('SESSION_TTL_HOURS', '12'))),
      migrationsDir: get('MIGRATIONS_DIR', '../infra/migrations'),
      seedAdminEmail: env['SEED_ADMIN_EMAIL'],
      seedAdminPassword: env['SEED_ADMIN_PASSWORD'],
      seedDemoUsers: get('SEED_DEMO_USERS', 'false') == 'true',
      webpostoBaseUrl: get('WEBPOSTO_BASE_URL', 'https://web.qualityautomacao.com.br')
          .replaceAll(RegExp(r'/+$'), ''),
      webpostoChave: get('WEBPOSTO_CHAVE', '').trim(),
    );
  }
}
