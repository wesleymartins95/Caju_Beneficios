--  STEP 5 — POPULAR FACT_TRANSACAO
--  Faz o lookup de todos os sk nas dimensões já populadas
--  e insere apenas registros novos (evita duplicata por transacao_id)
----------------------------------------------------------------------
INSERT INTO dbo.FACT_TRANSACAO (
    sk_data,
    sk_empresa,
    sk_colaborador,
    sk_produto,
    sk_localidade,
    sk_status,
    transacao_id,
    valor_brl,
    flag_aprovada,
    flag_estornada
)
SELECT
    -- lookup DIM_DATA (sk = YYYYMMDD inteiro)
    CAST(FORMAT(TRY_CAST(t.data_transacao AS DATE), 'yyyyMMdd') AS INT) AS sk_data,

    -- lookup DIM_EMPRESA via colaborador ? empresa
    e.sk_empresa,

    -- lookup DIM_COLABORADOR
    c.sk_colaborador,

    -- lookup DIM_PRODUTO
    p.sk_produto,

    -- lookup DIM_LOCALIDADE
    l.sk_localidade,

    -- lookup DIM_STATUS_TRANSACAO
    s.sk_status,

    -- chave natural
    t.transacao_id,

    -- métrica principal
    TRY_CAST(t.valor_brl AS DECIMAL(14,2)) AS valor_brl,

    -- flags derivadas do status
    CASE WHEN t.status_transacao = 'Aprovada'  THEN 1 ELSE 0 END AS flag_aprovada,
    CASE WHEN t.status_transacao = 'Estornada' THEN 1 ELSE 0 END AS flag_estornada

FROM dbo.STG_TRANSACOES t

-- JOIN DIM_EMPRESA: via empresa_id da staging de colaboradores
JOIN dbo.STG_COLABORADORES sc
    ON t.colaborador_id = sc.colaborador_id
JOIN dbo.DIM_EMPRESA e
    ON e.empresa_id = sc.empresa_id

-- JOIN DIM_COLABORADOR
JOIN dbo.DIM_COLABORADOR c
    ON c.colaborador_id = t.colaborador_id

-- JOIN DIM_PRODUTO
JOIN dbo.DIM_PRODUTO p
    ON  p.nome_produto       = t.produto
    AND p.categoria_produto  = t.categoria

-- JOIN DIM_LOCALIDADE
JOIN dbo.DIM_LOCALIDADE l
    ON  l.cidade           = t.cidade
    AND l.estado           = t.estado
    AND l.canal_transacao  = t.canal

-- JOIN DIM_STATUS_TRANSACAO
JOIN dbo.DIM_STATUS_TRANSACAO s
    ON s.status_transacao = t.status_transacao

-- Evita duplicata em re-execuções
WHERE t.transacao_id NOT IN (
    SELECT transacao_id FROM dbo.FACT_TRANSACAO
);
GO