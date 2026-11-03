import 'dart:io';

import '../config/config.dart';
import '../core/security.dart';
import '../modules/auth/auth_repository.dart';

/// Dados de desenvolvimento. Nao usar em producao (deixe SEED_* vazio).
Future<void> seedAdmin(AuthRepository repo, AppConfig config) async {
  final email = config.seedAdminEmail;
  final password = config.seedAdminPassword;
  if (email == null || password == null || email.isEmpty || password.isEmpty) return;

  await _ensureUser(repo, email: email, name: 'Administrador', password: password, role: 'admin');

  if (config.seedDemoUsers) {
    // Mesma senha do admin; cada um com acesso so a loja 01.
    await _ensureUser(repo, email: 'fiscal@conferencia.local', name: 'Maria Silva',
        registration: '4587', password: password, role: 'fiscal', storeId: 1);
    await _ensureUser(repo, email: 'tesouraria@conferencia.local', name: 'João Torres',
        registration: '3300', password: password, role: 'tesouraria', storeId: 1);
  }
}

Future<void> _ensureUser(
  AuthRepository repo, {
  required String email,
  required String name,
  required String password,
  required String role,
  String? registration,
  int? storeId,
}) async {
  if (await repo.userExists(email)) return;
  final id = await repo.createUser(
    email: email,
    name: name,
    registration: registration,
    passwordHash: hashPassword(password),
  );
  await repo.assignRole(id, role, storeId: storeId);
  stdout.writeln('usuario criado: $email ($role)');
}
