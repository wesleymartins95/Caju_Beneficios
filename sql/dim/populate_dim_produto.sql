-- 4.3 DIM_PRODUTO
--     Fonte: STG_TRANSACOES (produto + categoria são atributos da transação)
--     Deduplica combinações únicas de produto x categoria
MERGE dbo.DIM_PRODUTO AS tgt
USING (
    SELECT DISTINCT
        produto         AS nome_produto,
        categoria       AS categoria_produto,
        produto         AS linha,          -- linha = produto principal
        'Recorrente'    AS tipo_cobranca
    FROM dbo.STG_TRANSACOES
    WHERE produto   IS NOT NULL
      AND categoria IS NOT NULL
) AS src ON tgt.nome_produto       = src.nome_produto
         AND tgt.categoria_produto = src.categoria_produto
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nome_produto, categoria_produto, linha, tipo_cobranca)
    VALUES (src.nome_produto, src.categoria_produto, src.linha, src.tipo_cobranca);
GO