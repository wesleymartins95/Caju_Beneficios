--  Dimensão degenerada de status e motivo de negação
-- ============================================================
CREATE TABLE dbo.DIM_STATUS_TRANSACAO (
    sk_status           TINYINT       NOT NULL CONSTRAINT PK_DIM_STATUS PRIMARY KEY,
    status_transacao    VARCHAR(30)   NOT NULL,   -- 'Aprovada', 'Negada', 'Estornada'
    motivo_negacao      VARCHAR(100)  NULL,       -- preenchido só quando Negada
    is_aprovada         BIT           NOT NULL DEFAULT 0
);
GO