-- FACT_TRANSACAO ( TABELA CENTRAL DO MODELO STAR SCHEMA)
-- GRANULARIDADE : 1 linha = 1 transação
-- MÉTRICAS: valor_brl, flag_aprovada,flag_estornada
CREATE TABLE FACT_TRANSACAO(
	sk_transacao BIGINT NOT NULL CONSTRAINT PK_FACT_TRANSACAO PRIMARY KEY IDENTITY(1,1),

	-- chaves estrangeiras para as dimensões
	sk_data INT NOT NULL,
	sk_empresa INT NOT NULL,
	sk_colaborador INT NOT NULL,
	sk_produto INT NOT NULL,
	sk_localidade INT NOT NULL,
	sk_status TINYINT NOT NULL,
	
	-- chave natural (rastreabilidade para o sistema source)
	transacao_id        VARCHAR(10)   NOT NULL,
 
    -- Métricas aditivas
    valor_brl           DECIMAL(14,2) NOT NULL,
    saldo_antes_brl     DECIMAL(14,2) NULL,
    saldo_depois_brl    DECIMAL(14,2) NULL,
 
    -- Flags (métricas semi-aditivas)
    flag_aprovada       BIT           NOT NULL DEFAULT 0,
    flag_estornada      BIT           NOT NULL DEFAULT 0,
 
    -- Auditoria de carga
    dt_carga            DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
	
	-- FOREIGN KEYS
	CONSTRAINT FK_FACT_DATA        FOREIGN KEY (sk_data)        REFERENCES dbo.DIM_DATA(sk_data),
    CONSTRAINT FK_FACT_EMPRESA     FOREIGN KEY (sk_empresa)     REFERENCES dbo.DIM_EMPRESA(sk_empresa),
    CONSTRAINT FK_FACT_COLABORADOR FOREIGN KEY (sk_colaborador) REFERENCES dbo.DIM_COLABORADOR(sk_colaborador),
    CONSTRAINT FK_FACT_PRODUTO     FOREIGN KEY (sk_produto)     REFERENCES dbo.DIM_PRODUTO(sk_produto),
    CONSTRAINT FK_FACT_LOCALIDADE  FOREIGN KEY (sk_localidade)  REFERENCES dbo.DIM_LOCALIDADE(sk_localidade),
    CONSTRAINT FK_FACT_STATUS      FOREIGN KEY (sk_status)      REFERENCES dbo.DIM_STATUS_TRANSACAO(sk_status)
);
GO
--  ÍNDICES — otimizados para os slices mais comuns
--  (por data, por empresa, por produto)
-- ============================================================
CREATE NONCLUSTERED INDEX IX_FACT_DATA
    ON dbo.FACT_TRANSACAO(sk_data) INCLUDE (valor_brl, flag_aprovada);
 
CREATE NONCLUSTERED INDEX IX_FACT_EMPRESA
    ON dbo.FACT_TRANSACAO(sk_empresa) INCLUDE (sk_data, valor_brl);
 
CREATE NONCLUSTERED INDEX IX_FACT_PRODUTO
    ON dbo.FACT_TRANSACAO(sk_produto) INCLUDE (sk_data, valor_brl);
 
CREATE NONCLUSTERED INDEX IX_FACT_STATUS
    ON dbo.FACT_TRANSACAO(sk_status) INCLUDE (valor_brl);
GO