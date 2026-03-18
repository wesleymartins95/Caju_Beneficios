-- ============================================================
--  CAJU BENEFÍCIOS — CARGA COMPLETA VIA BULK INSERT
--  Fluxo: CSV / Staging Tables / Dimensões / Fato
--
--  Executar na ordem: Steps 1 ? 2 ? 3 ? 4 ? 5 ? 6
-- ============================================================

USE Caju_dw;
GO
--  STEP 1 — CRIAR STAGING TABLES (espelho exato dos CSVs)
--  São temporárias por sessão; DROP + CREATE garante idempotência
---------------------------------------------------------------------
-- 1.1 Staging: clientes
DROP TABLE IF EXISTS dbo.STG_CLIENTES;
CREATE TABLE dbo.STG_CLIENTES (
    empresa_id      VARCHAR(10),
    razao_social    VARCHAR(200),
    segmento        VARCHAR(100),
    porte           VARCHAR(20),
    cidade          VARCHAR(100),
    estado          CHAR(2),
    data_contrato   VARCHAR(20),   -- varchar p/ aceitar raw do CSV
    mrr_brl         VARCHAR(20),
    status          VARCHAR(20),
    gestor_cs       VARCHAR(100),
    nps_ultimo      VARCHAR(10)
);

-- 1.2 Staging: colaboradores
DROP TABLE IF EXISTS dbo.STG_COLABORADORES;
CREATE TABLE dbo.STG_COLABORADORES (
    colaborador_id          VARCHAR(10),
    empresa_id              VARCHAR(10),
    produto                 VARCHAR(100),
    data_ativacao           VARCHAR(20),
    status                  VARCHAR(20),
    saldo_disponivel_brl    VARCHAR(20),
    gasto_mes_brl           VARCHAR(20),
    categoria_gasto         VARCHAR(100),
    frequencia_uso_mensal   VARCHAR(10)
);

-- 1.3 Staging: transações
DROP TABLE IF EXISTS dbo.STG_TRANSACOES;
CREATE TABLE dbo.STG_TRANSACOES (
    transacao_id        VARCHAR(10),
    colaborador_id      VARCHAR(10),
    empresa_id          VARCHAR(10),
    data_transacao      VARCHAR(20),
    produto             VARCHAR(100),
    categoria           VARCHAR(100),
    valor_brl           VARCHAR(20),
    status_transacao    VARCHAR(30),
    canal               VARCHAR(30),
    cidade              VARCHAR(100),
    estado              CHAR(2)
);
GO