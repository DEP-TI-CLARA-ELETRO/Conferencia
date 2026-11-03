import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

/// Aplica os arquivos `NNNN_nome.sql` da pasta de migrations, em ordem,
/// registrando o que ja foi aplicado em `schema_migrations`.
Future<void> runMigrations(Pool<void> pool, String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    throw StateError('Pasta de migrations nao encontrada: ${folder.absolute.path}');
  }

  await pool.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version     TEXT PRIMARY KEY,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  ''');

  final applied = (await pool.execute('SELECT version FROM schema_migrations'))
      .map((r) => r[0] as String)
      .toSet();

  final files = folder
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

  for (final file in files) {
    final version = p.basenameWithoutExtension(file.path);
    if (applied.contains(version)) continue;

    final sql = await file.readAsString();
    await pool.runTx((tx) async {
      await tx.execute(sql, queryMode: QueryMode.simple);
      await tx.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@v)'),
        parameters: {'v': version},
      );
    });
    stdout.writeln('migration aplicada: $version');
  }
}
