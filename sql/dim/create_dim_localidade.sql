--  Onde a transação ocorreu + canal de uso
-- ============================================================
CREATE TABLE dbo.DIM_LOCALIDADE (
    sk_localidade       INT           NOT NULL CONSTRAINT PK_DIM_LOCALIDADE PRIMARY KEY IDENTITY(1,1),
    cidade              VARCHAR(100)  NULL,
    estado              CHAR(2)       NULL,
    regiao              VARCHAR(20)   NULL,       -- 'Sudeste', 'Sul'…
    canal_transacao     VARCHAR(30)   NULL,       -- 'App', 'Físico', 'Online'
    dt_carga            DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO