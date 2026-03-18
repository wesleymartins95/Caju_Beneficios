-- Linha de produtos: Beneficios,Despesas,Premiações,Ciclos
CREATE TABLE dbo.DIM_PRODUTO (
    sk_produto          INT           NOT NULL CONSTRAINT PK_DIM_PRODUTO PRIMARY KEY IDENTITY(1,1),
    nome_produto        VARCHAR(100)  NOT NULL,
    categoria_produto   VARCHAR(100)  NULL,       -- categoria de gasto (Alimentação, Saúde…)
    linha               VARCHAR(100)  NULL,       -- 'Cartão Multi Benefícios', 'Despesas Corporativas'…
    tipo_cobranca       VARCHAR(50)   NULL,       -- 'Recorrente', 'Avulso'
    dt_carga            DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO