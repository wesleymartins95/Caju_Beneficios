-- 4.4 DIM_LOCALIDADE
--     Fonte: STG_TRANSACOES (cidade + estado + canal)
--     Deduplica combinações únicas
MERGE dbo.DIM_LOCALIDADE AS tgt
USING (
    SELECT DISTINCT
        cidade,
        estado,
        CASE estado
            WHEN 'SP' THEN 'Sudeste'
            WHEN 'RJ' THEN 'Sudeste'
            WHEN 'MG' THEN 'Sudeste'
            WHEN 'ES' THEN 'Sudeste'
            WHEN 'RS' THEN 'Sul'
            WHEN 'SC' THEN 'Sul'
            WHEN 'PR' THEN 'Sul'
            WHEN 'BA' THEN 'Nordeste'
            WHEN 'PE' THEN 'Nordeste'
            WHEN 'CE' THEN 'Nordeste'
            WHEN 'GO' THEN 'Centro-Oeste'
            WHEN 'MT' THEN 'Centro-Oeste'
            WHEN 'MS' THEN 'Centro-Oeste'
            WHEN 'DF' THEN 'Centro-Oeste'
            WHEN 'AM' THEN 'Norte'
            WHEN 'PA' THEN 'Norte'
            ELSE 'Outros'
        END AS regiao,
        canal AS canal_transacao
    FROM dbo.STG_TRANSACOES
    WHERE cidade IS NOT NULL
) AS src ON tgt.cidade           = src.cidade
         AND tgt.estado          = src.estado
         AND tgt.canal_transacao = src.canal_transacao
WHEN NOT MATCHED BY TARGET THEN
    INSERT (cidade, estado, regiao, canal_transacao)
    VALUES (src.cidade, src.estado, src.regiao, src.canal_transacao);
GO