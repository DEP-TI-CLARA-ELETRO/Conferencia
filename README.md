# Conferencia de Caixas

Sistema para acompanhar caixas fechados e conferir valores apresentados x apurados.

## Estrutura

- `app/` Flutter (web + Android + iOS)
- `server/` API em Dart + Shelf
- `shared/` pacote Dart compartilhado (enums e DTOs)
- `infra/` Docker (PostgreSQL) e migrations SQL
- `docs/referencias/` imagens de referencia do gerente
- `docs/negocio.md` contexto do Grupo Clara, ERPs e escopo do MVP
- `docs/integracoes/` WebPosto (OpenAPI + resumo das rotas de caixa)

## Ambiente de desenvolvimento

Requisitos: Flutter SDK (stable), Chrome, Docker Desktop. Para celular: Android Studio / SDK (e emulador).

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

# 3. App (web)
cd ../app
flutter pub get
flutter run -d chrome

# 3b. App (Android — emulador ou aparelho)
flutter emulators --launch Medium_Phone_API_37.0
flutter run -d android
# Celular físico na mesma rede: use o IP do PC
# flutter run -d android --dart-define=API_URL=http://192.168.x.x:8080
```

No emulador Android a API padrão é `http://10.0.2.2:8080` (o `localhost` do PC).
iOS precisa de Mac + Xcode; o projeto `app/ios` já está gerado.

Sem Docker (ex.: virtualizacao desativada), use qualquer PostgreSQL 16 local com o banco/usuario
`conferencia` / senha `conferencia_dev` (valores de `infra/.env.example`).

Login de desenvolvimento (com `SEED_DEMO_USERS=true` tambem existem `fiscal@` e `tesouraria@conferencia.local`, mesma senha): `admin@conferencia.local` / `admin123`.

### WebPosto (postos)

No `server/.env`:

```env
WEBPOSTO_BASE_URL=https://web.qualityautomacao.com.br
WEBPOSTO_CHAVE=sua_chave_aqui
```

Reinicie a API. No app: **Caixas do dia** → **Sincronizar WebPosto** (usa a data da barra superior).
Detalhes: `docs/integracoes/webposto.md`.

### Cupom de fechamento (OCR)

No `server/.env`:

```env
COUPONS_UPLOAD_DIR=uploads/coupons
GOOGLE_VISION_API_KEY=sua_chave_vision
TESSERACT_BIN=tesseract
```

Instale o [Tesseract](https://github.com/tesseract-ocr/tesseract) no PC (idioma `por` recomendado). Sem a chave Vision ou sem o Tesseract, o upload ainda funciona; a leitura fica parcial e o usuário confirma os valores na tela.

Fluxo operacional:

1. Abra um caixa já importado (WebPosto ou outro conector).
2. **Fotografar** (mobile) ou **Enviar imagem** (web) do cupom de fechamento.
3. A API grava a imagem em `COUPONS_UPLOAD_DIR` e roda Vision + Tesseract; campos em que os motores divergem aparecem destacados.
4. Revise/corrija os valores e toque em **Confirmar e cruzar com ERP**.
5. O servidor compara com `payment_breakdown` do caixa e grava bateu / divergente. Sem confirmação humana o cupom fica só como rascunho.
