# Conferência de Caixas (MERN)

Stack: **MongoDB + Express + React + Node**.

## Subir local

```bash
# Mongo (Docker) — ou use um Mongo já em :27017
docker compose -f infra/docker-compose.yml up -d --remove-orphans

# API
cd api
cp ../infra/.env.example .env   # ajuste MONGODB_URI / WEBPOSTO_CHAVE
npm install
npm run dev                     # http://127.0.0.1:8080

# Client
cd ../client
npm install
npm run dev                     # http://127.0.0.1:8081 (proxy para API)
```

Seed padrão (se `SEED_*` no `.env`):

- `admin@conferencia.local` / `admin123`
- `fiscal@conferencia.local` / `admin123`
- `tesouraria@conferencia.local` / `admin123`

## Produção

```bash
cd client && npm run build
cd ../api && npm start   # serve client/dist + API na :8080
```

## Docs de negócio

Ver [`docs/negocio.md`](docs/negocio.md) e [`docs/integracoes/webposto.md`](docs/integracoes/webposto.md).
