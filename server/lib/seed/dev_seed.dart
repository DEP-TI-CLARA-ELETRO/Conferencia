import 'dart:io';

import '../config/config.dart';
import '../core/security.dart';
import '../modules/auth/auth_repository.dart';

/// Dados de DESENVOLVIMENTO. Não use SEED_* em produção (deixe vazio).
Future<void> seedAdmin(AuthRepository repo, AppConfig config) async {
  final email = config.seedAdminEmail;
  final password = config.seedAdminPassword;
  // Se não configurou e-mail/senha de seed, não cria ninguém
  if (email == null || password == null || email.isEmpty || password.isEmpty) return;

  await _ensureUser(
    repo,
    email: email,
    name: 'Administrador',
    password: password,
    role: 'admin',
  );

  // Usuários de exemplo para testar menu por perfil
  if (config.seedDemoUsers) {
    await _ensureUser(
      repo,
      email: 'fiscal@conferencia.local',
      name: 'Maria Silva',
      registration: '4587',
      password: password, // mesma senha do admin só em dev
      role: 'fiscal',
      storeId: 1, // só Loja 01
    );
    await _ensureUser(
      repo,
      email: 'tesouraria@conferencia.local',
      name: 'João Torres',
      registration: '3300',
      password: password,
      role: 'tesouraria',
      storeId: 1,
    );
  }
}

/// Cria o usuário só se o e-mail ainda não existir (idempotente).
Future<void> _ensureUser(
  AuthRepository repo, {
  required String email,
  required String name,
  required String password,
  required String role,
  String? registration,
  int? storeId,
}) async {
  if (await repo.userExists(email)) return; // já existe: não faz nada
  final id = await repo.createUser(
    email: email,
    name: name,
    registration: registration,
    passwordHash: hashPassword(password), // grava hash, nunca a senha pura
  );
  await repo.assignRole(id, role, storeId: storeId);
  stdout.writeln('usuario criado: $email ($role)');
}
