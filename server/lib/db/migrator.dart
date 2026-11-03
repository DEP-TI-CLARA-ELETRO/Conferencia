import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

/// Aplica os arquivos `NNNN_nome.sql` da pasta de migrations, em ordem.
/// Guarda o que já rodou na tabela `schema_migrations` para não repetir.
Future<void> runMigrations(Pool<void> pool, String dir) async {
  final folder = Directory(dir);
  if (!folder.existsSync()) {
    // StateError = erro grave de configuração (pasta errada)
    throw StateError('Pasta de migrations nao encontrada: ${folder.absolute.path}');
  }

  // Garante que a tabela de controle existe
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version     TEXT PRIMARY KEY,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  ''');

  // Quais versões já foram aplicadas?
  final applied = (await pool.execute('SELECT version FROM schema_migrations'))
      .map((r) => r[0] as String) // cada linha: coluna 0 = version
      .toSet(); // Set = conjunto (busca rápida com contains)

  // Lista arquivos .sql, ordena pelo nome (0001..., 0002...)
  final files = folder
      .listSync()
      .whereType<File>() // só arquivos (ignora subpastas)
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  // ..sort = "cascade": ordena a lista e continua usando a mesma variável

  for (final file in files) {
    // basenameWithoutExtension("0001_auth.sql") -> "0001_auth"
    final version = p.basenameWithoutExtension(file.path);
    if (applied.contains(version)) continue; // já aplicada: pula

    final sql = await file.readAsString();
    // runTx = transação: ou aplica TUDO ou não aplica nada (segurança)
    await pool.runTx((tx) async {
      await tx.execute(sql, queryMode: QueryMode.simple);
      await tx.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@v)'),
        parameters: {'v': version}, // @v é substituído com segurança (anti SQL injection)
      );
    });
    stdout.writeln('migration aplicada: $version');
  }
}
