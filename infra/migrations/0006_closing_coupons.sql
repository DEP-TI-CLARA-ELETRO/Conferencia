-- Cupons de fechamento (foto/scan) ancorados em cash_closings
CREATE TABLE IF NOT EXISTS closing_coupons (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    closing_id          UUID NOT NULL REFERENCES cash_closings(id) ON DELETE CASCADE,
    storage_path        TEXT NOT NULL,
    original_filename   TEXT,
    content_type        TEXT,
    status              TEXT NOT NULL DEFAULT 'uploaded',
    -- uploaded | ocr_pending | ocr_ready | confirmed | failed
    proposed_values     JSONB NOT NULL DEFAULT '{}'::jsonb,
    confirmed_values    JSONB,
    match_result        JSONB,
    ocr_warning         TEXT,
    created_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    confirmed_by        UUID REFERENCES users(id) ON DELETE SET NULL,
    confirmed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS closing_coupons_closing_idx
    ON closing_coupons (closing_id, created_at DESC);

CREATE TABLE IF NOT EXISTS closing_coupon_ocr_runs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id       UUID NOT NULL REFERENCES closing_coupons(id) ON DELETE CASCADE,
    engine          TEXT NOT NULL,
    -- vision | tesseract
    raw_text        TEXT,
    parsed_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence      NUMERIC(5, 4),
    error           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS closing_coupon_ocr_runs_coupon_idx
    ON closing_coupon_ocr_runs (coupon_id, engine);
