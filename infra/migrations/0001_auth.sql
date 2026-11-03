-- =============================================================================
-- Migration 0001: autenticação, perfis, permissões, sessões e auditoria
--
-- Em SQL, linhas que começam com -- são comentários.
-- Esta migration cria as tabelas base. O migrator Dart aplica cada arquivo
-- uma única vez e registra em schema_migrations.
-- =============================================================================

-- Lojas da empresa
CREATE TABLE stores (
    id          SERIAL PRIMARY KEY,          -- número automático (1, 2, 3...)
    code        TEXT NOT NULL UNIQUE,        -- código curto, único (ex.: '01')
    name        TEXT NOT NULL,               -- nome amigável
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()  -- data/hora com fuso
);

-- Perfis (admin, fiscal, tesouraria...)
CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,        -- chave técnica
    name        TEXT NOT NULL                -- rótulo
);

-- Permissões granulares (home.view, closings.fiscal...)
CREATE TABLE permissions (
    id          SERIAL PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT ''
);

-- Relação N:N entre perfil e permissão
-- PRIMARY KEY composta = um perfil não tem a mesma permissão duas vezes
CREATE TABLE role_permissions (
    role_id       INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Usuários (id UUID gerado pelo Postgres)
CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email          TEXT NOT NULL UNIQUE,
    name           TEXT NOT NULL,
    registration   TEXT,                     -- matrícula (opcional)
    password_hash  TEXT NOT NULL,            -- NUNCA a senha em texto puro
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at  TIMESTAMPTZ
);

-- Usuário x perfil x loja
-- store_id NULL = acesso a TODAS as lojas
CREATE TABLE user_roles (
    id        SERIAL PRIMARY KEY,
    user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id   INT  NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    store_id  INT  REFERENCES stores(id) ON DELETE CASCADE
);
-- Índice único considerando NULL como 0 (evita duplicata "todas as lojas")
CREATE UNIQUE INDEX user_roles_unique
    ON user_roles (user_id, role_id, COALESCE(store_id, 0));

-- Sessões: guardamos só o HASH do token (não o token em claro)
CREATE TABLE sessions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,                 -- preenchido no logout
    ip          TEXT,
    user_agent  TEXT
);
CREATE INDEX sessions_user_idx ON sessions (user_id);

-- Trilha de auditoria (login, logout, falhas...)
CREATE TABLE audit_log (
    id          BIGSERIAL PRIMARY KEY,       -- número grande auto-incremento
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    action      TEXT NOT NULL,
    entity      TEXT,
    entity_id   TEXT,
    details     JSONB,                       -- detalhes flexíveis em JSON
    ip          TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audit_log_user_idx ON audit_log (user_id, created_at DESC);
