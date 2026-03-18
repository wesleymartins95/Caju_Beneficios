USE Caju_dw
GO

-- Permite filtros por ano,trimestre,mes,dia da semana
CREATE TABLE dbo.DIM_DATA(
	sk_data INT NOT NULL CONSTRAINT PK_DIM_DATA PRIMARY KEY,
	data_completa DATE NOT NULL,
	ano SMALLINT NOT NULL,
	trimestre TINYINT NOT NULL, -- 1-4
	mes_numero TINYINT NOT NULL,
	mes_nome VARCHAR(20) NOT NULL,
	semana_ano TINYINT NOT NULL, --ISO WEEK
	dia_mes             TINYINT       NOT NULL,
	dia_semana_numero   TINYINT       NOT NULL,   -- 1=Dom ... 7=Sab
	dia_semana_nome     VARCHAR(20)   NOT NULL,
	is_fim_semana       BIT           NOT NULL DEFAULT 0,
	mes_ano_label       CHAR(7)       NOT NULL    -- 'YYYY-MM'  ex: '2025-03'
);
GO