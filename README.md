# Conferencia de Caixas

Sistema para acompanhar caixas fechados e conferir valores apresentados x apurados.

## Estrutura

- `app/` Flutter Web (interface)
- `server/` API em Dart + Shelf
- `shared/` pacote Dart compartilhado (enums e DTOs)
- `infra/` Docker (PostgreSQL) e migrations SQL
- `docs/referencias/` imagens de referencia do gerente

## Ambiente de desenvolvimento

Requisitos: Flutter SDK (stable), Chrome, Docker Desktop.

```powershell
# 1. Banco
cd infra
copy .env.example .env
docker compose up -d

# 2. API (aplica migrations e cria o seed ao iniciar)
cd ../server
copy ../infra/.env.example .env
dart pub get
dart run bin/server.dart

# 3. App
cd ../app
flutter pub get
flutter run -d chrome
```

Sem Docker (ex.: virtualizacao desativada), use qualquer PostgreSQL 16 local com o banco/usuario
`conferencia` / senha `conferencia_dev` (valores de `infra/.env.example`).

Login de desenvolvimento (com `SEED_DEMO_USERS=true` tambem existem `fiscal@` e `tesouraria@conferencia.local`, mesma senha): `admin@conferencia.local` / `admin123`.
