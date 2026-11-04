-- Lojas: conector de integração + código externo (ex.: empresaCodigo do WebPosto)
ALTER TABLE stores ADD COLUMN IF NOT EXISTS connector TEXT NOT NULL DEFAULT 'manual';
ALTER TABLE stores ADD COLUMN IF NOT EXISTS external_code TEXT;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS business_unit TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS stores_connector_external_uidx
    ON stores (connector, external_code)
    WHERE external_code IS NOT NULL;

-- Fechamentos importados (MVP: WebPosto / postos)
CREATE TABLE IF NOT EXISTS cash_closings (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id              INT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    connector             TEXT NOT NULL DEFAULT 'webposto',
    external_codigo       INT,                 -- campo "codigo" da API (paginação)
    external_caixa_codigo INT NOT NULL,        -- caixaCodigo
    movement_date         DATE NOT NULL,
    shift_code            INT,
    shift_label           TEXT,
    pdv_code              INT,
    employee_code         INT,
    opened_at             TIMESTAMPTZ,
    closed_at             TIMESTAMPTZ,
    closed                BOOLEAN NOT NULL DEFAULT FALSE,
    consolidated          BOOLEAN NOT NULL DEFAULT FALSE,
    blocked               BOOLEAN NOT NULL DEFAULT FALSE,
    apurado               NUMERIC(14, 2),
    diferenca             NUMERIC(14, 2),
    stage                 TEXT NOT NULL DEFAULT 'pdv_imported',
    payment_breakdown    JSONB NOT NULL DEFAULT '{}'::jsonb,
    raw_caixa             JSONB,
    raw_apresentado       JSONB,
    synced_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Evita duplicar o mesmo fechamento na mesma loja/dia/turno/caixa
CREATE UNIQUE INDEX IF NOT EXISTS cash_closings_natural_uidx
    ON cash_closings (
        store_id,
        connector,
        external_caixa_codigo,
        movement_date,
        COALESCE(shift_code, -1)
    );

CREATE INDEX IF NOT EXISTS cash_closings_store_date_idx
    ON cash_closings (store_id, movement_date DESC);
