import 'package:postgres/postgres.dart';

import '../config/config.dart';

Pool<void> createPool(AppConfig c) {
  return Pool.withEndpoints(
    [
      Endpoint(
        host: c.dbHost,
        port: c.dbPort,
        database: c.dbName,
        username: c.dbUser,
        password: c.dbPassword,
      ),
    ],
    settings: const PoolSettings(
      maxConnectionCount: 10,
      sslMode: SslMode.disable,
    ),
  );
}
