--  STEP 4 — POPULAR DIMENSÕES DE ATRIBUTO

-- 4.1 DIM_EMPRESA
--     Fonte: STG_CLIENTES
--     Usa MERGE para ser idempotente (re-executável sem duplicar)
MERGE dbo.DIM_EMPRESA AS tgt
USING (
    SELECT
        empresa_id,
        razao_social,
        segmento,
        porte,
        cidade,
        estado,
        gestor_cs,
        status          AS status_cliente,
        TRY_CAST(mrr_brl       AS DECIMAL(14,2)) AS mrr_brl,
        TRY_CAST(data_contrato AS DATE)          AS data_contrato
    FROM dbo.STG_CLIENTES
) AS src ON tgt.empresa_id = src.empresa_id
WHEN MATCHED THEN
    UPDATE SET
        razao_social   = src.razao_social,
        segmento       = src.segmento,
        porte          = src.porte,
        cidade         = src.cidade,
        estado         = src.estado,
        gestor_cs      = src.gestor_cs,
        status_cliente = src.status_cliente,
        mrr_brl        = src.mrr_brl,
        data_contrato  = src.data_contrato,
        data_carga       = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (empresa_id, razao_social, segmento, porte, cidade, estado,
            gestor_cs, status_cliente, mrr_brl, data_contrato)
    VALUES (src.empresa_id, src.razao_social, src.segmento, src.porte,
            src.cidade, src.estado, src.gestor_cs, src.status_cliente,
            src.mrr_brl, src.data_contrato);
GO