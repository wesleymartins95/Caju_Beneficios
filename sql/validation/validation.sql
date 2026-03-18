--  STEP 6 — VALIDAÇÃO PÓS-CARGA
--  Rode após os steps para conferir os totais
-- ============================================================

-- Contagem de registros por tabela
SELECT 'DIM_DATA'               AS tabela, COUNT(*) AS qtd_linhas FROM dbo.DIM_DATA
UNION ALL
SELECT 'DIM_EMPRESA',                      COUNT(*)              FROM dbo.DIM_EMPRESA
UNION ALL
SELECT 'DIM_COLABORADOR',                  COUNT(*)              FROM dbo.DIM_COLABORADOR
UNION ALL
SELECT 'DIM_PRODUTO',                      COUNT(*)              FROM dbo.DIM_PRODUTO
UNION ALL
SELECT 'DIM_LOCALIDADE',                   COUNT(*)              FROM dbo.DIM_LOCALIDADE
UNION ALL
SELECT 'DIM_STATUS_TRANSACAO',             COUNT(*)              FROM dbo.DIM_STATUS_TRANSACAO
UNION ALL
SELECT 'FACT_TRANSACAO',                   COUNT(*)              FROM dbo.FACT_TRANSACAO;
GO

-- Verifica se há FKs órfãs na Fato (deve retornar 0 linhas)
SELECT 'Empresa sem DIM'     AS problema, COUNT(*) AS qtd
FROM dbo.FACT_TRANSACAO f
LEFT JOIN dbo.DIM_EMPRESA e ON f.sk_empresa = e.sk_empresa
WHERE e.sk_empresa IS NULL
UNION ALL
SELECT 'Colaborador sem DIM', COUNT(*)
FROM dbo.FACT_TRANSACAO f
LEFT JOIN dbo.DIM_COLABORADOR c ON f.sk_colaborador = c.sk_colaborador
WHERE c.sk_colaborador IS NULL
UNION ALL
SELECT 'Data sem DIM',         COUNT(*)
FROM dbo.FACT_TRANSACAO f
LEFT JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
WHERE d.sk_data IS NULL;
GO

-- Validação de duplicidade
SELECT sk_transacao, COUNT(*) 
FROM dbo.FACT_TRANSACAO
GROUP BY sk_transacao
HAVING COUNT(*) > 1;

-- checando valores nulos
SELECT COUNT(*) AS qtd_nulos_valor
FROM dbo.FACT_TRANSACAO
WHERE valor_brl IS NULL;

-- Verificando se o volume de dados carregado bate com a origem.
SELECT COUNT(*) AS qtd_staging, COUNT(*) AS qtd_fact
FROM dbo.STG_TRANSACOES, dbo.FACT_TRANSACAO;


-- Receita total carregada — confira contra o CSV original
SELECT
    COUNT(*)                            AS total_transacoes,
    SUM(valor_brl)                      AS receita_total_brl,
    SUM(CASE WHEN flag_aprovada = 1
             THEN valor_brl ELSE 0 END) AS receita_aprovada_brl,
    AVG(valor_brl)                      AS ticket_medio_brl
FROM dbo.FACT_TRANSACAO;
GO