-- 4.2 DIM_COLABORADOR
--     Fonte: STG_COLABORADORES
MERGE dbo.DIM_COLABORADOR AS tgt
USING (
    SELECT
        colaborador_id,
        empresa_id,
        produto                                              AS produto_principal,
        TRY_CAST(data_ativacao AS DATE)                     AS data_ativacao,
        status                                              AS status_colaborador,
        TRY_CAST(frequencia_uso_mensal AS TINYINT)          AS frequencia_uso_mensal
    FROM dbo.STG_COLABORADORES
) AS src ON tgt.colaborador_id = src.colaborador_id
WHEN MATCHED THEN
    UPDATE SET
        empresa_id            = src.empresa_id,
        produto_principal     = src.produto_principal,
        data_ativacao         = src.data_ativacao,
        status_colaborador    = src.status_colaborador,
        frequencia_uso_mensal = src.frequencia_uso_mensal,
        dt_carga              = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (colaborador_id, empresa_id, produto_principal,
            data_ativacao, status_colaborador, frequencia_uso_mensal)
    VALUES (src.colaborador_id, src.empresa_id, src.produto_principal,
            src.data_ativacao, src.status_colaborador, src.frequencia_uso_mensal);
GO