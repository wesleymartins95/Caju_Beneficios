-- Empresas clientes da CAJU (grandes e pequenas contas)
CREATE TABLE dbo.DIM_EMPRESA(
	sk_empresa INT NOT NULL CONSTRAINT PK_DIM_EMPRESA PRIMARY KEY IDENTITY(1,1),
	empresa_id VARCHAR(10) NOT NULL,
	razao_social        VARCHAR(200)  NOT NULL,
	segmento VARCHAR(100) NULL,
	porte VARCHAR(20) NULL, --SMB,MID-MARKET,ENTERPRISE
	cidade VARCHAR(100) NULL,
	estado VARCHAR(2) NULL,
	gestor_cs VARCHAR(100) NULL,
	status_cliente VARCHAR(20) NULL, --ATIVO,CHURN,EM RISCO
	mrr_brl DECIMAL(14,2) NULL,
	data_contrato DATE null,
	-- SCD Tipo 1(sobrescreve) - se precisar de histórico, promover p/ Tipo 2
	data_carga DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO