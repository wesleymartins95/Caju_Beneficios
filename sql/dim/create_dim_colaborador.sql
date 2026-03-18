-- Usuarios finais que utilizam os produtos CAJU
CREATE TABLE dbo.DIM_COLABORADOR(
	sk_colaborador INT NOT NULl CONSTRAINT PK_DIM_COLABORADOR PRIMARY KEY IDENTITY(1,1),
	colaborador_id VARCHAR(10) NOT NULL,
	empresa_id VARCHAR(10) NOT NULL, -- FK NATURAL (JOIN OPCIONAL C/ DIM_EMPRESA)
	produto_principal   VARCHAR(100)  NULL,
    status_colaborador  VARCHAR(20)   NULL,       -- 'Ativo', 'Inativo', 'Bloqueado'
    data_ativacao       DATE          NULL,
    frequencia_uso_mensal TINYINT     NULL,
    dt_carga            DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO 