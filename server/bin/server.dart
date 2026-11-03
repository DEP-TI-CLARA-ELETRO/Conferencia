import 'dart:io';

import 'package:server/app_server.dart';
import 'package:server/config/config.dart';
import 'package:server/db/database.dart';
import 'package:server/db/migrator.dart';
import 'package:server/modules/auth/auth_repository.dart';
import 'package:server/seed/dev_seed.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  final config = AppConfig.load();
  final db = createPool(config);

  await runMigrations(db, config.migrationsDir);

  final authRepo = AuthRepository(db);
  await seedAdmin(authRepo, config);

  final server = await io.serve(
    buildHandler(config, db, authRepo),
    InternetAddress.anyIPv4,
    config.serverPort,
  );
  stdout.writeln('API em http://localhost:${server.port}');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    await db.close();
    exit(0);
  });
}
