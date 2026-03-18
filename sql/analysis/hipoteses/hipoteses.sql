-- RESPONDENDO PERGUNTAS DE NEGOCIOS--
USE Caju_dw;
GO

-- Questões de negócio (conhecendo os dados) --

-- GASTOS

-- Quais colaboradores concentram os maiores gastos e quais permanecem sem movimentação

SELECT
    c.colaborador_id,
    e.razao_social                          AS empresa,
    e.porte,
    e.segmento,
    p.categoria_produto                     AS categoria_beneficio,
    d.mes_ano_label                         AS mes_ref,
    COUNT(*)                                AS qtd_transacoes,
    SUM(f.valor_brl)                        AS total_gasto_brl,
    AVG(f.valor_brl)                        AS ticket_medio_brl,
    MAX(f.valor_brl)                        AS maior_transacao_brl
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_COLABORADOR      c ON f.sk_colaborador = c.sk_colaborador
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa     = e.sk_empresa
JOIN dbo.DIM_PRODUTO          p ON f.sk_produto     = p.sk_produto
JOIN dbo.DIM_DATA             d ON f.sk_data        = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status      = s.sk_status
WHERE s.is_aprovada  = 1
  AND d.mes_ano_label = FORMAT(GETDATE(), 'yyyy-MM')   -- mês atual
GROUP BY
    c.colaborador_id, e.razao_social, e.porte,
    e.segmento, p.categoria_produto, d.mes_ano_label
ORDER BY total_gasto_brl DESC;
GO


	
-- GASTO POR ÁREA E SEGMENTO
-- Quais segmentos de empresa concentram maior uso em cada tipo de benefício
SELECT
    e.segmento,
    e.porte,
    p.linha                                 AS produto_caju,
    p.categoria_produto                     AS categoria,
    d.mes_ano_label,
    COUNT(DISTINCT f.sk_colaborador)        AS colaboradores_ativos,
    COUNT(DISTINCT f.sk_empresa)            AS empresas_ativas,
    SUM(f.valor_brl)                        AS total_gasto_brl,
    SUM(f.valor_brl)
        / NULLIF(COUNT(DISTINCT f.sk_colaborador), 0) AS gasto_medio_por_colaborador
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa  = e.sk_empresa
JOIN dbo.DIM_PRODUTO          p ON f.sk_produto  = p.sk_produto
JOIN dbo.DIM_DATA             d ON f.sk_data     = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status   = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY e.segmento, e.porte, p.linha, p.categoria_produto, d.mes_ano_label
ORDER BY d.mes_ano_label DESC, total_gasto_brl DESC;
GO

-- RANKING ENGAJAMENTO 
-- Quais colaboradores demonstram maior engajamento no uso dos benefícios e quais nunca utilizam
SELECT
    c.colaborador_id,
    e.razao_social                          AS empresa,
    e.porte,
    c.status_colaborador,
    COUNT(*)                                AS total_transacoes_historico,
    COUNT(DISTINCT d.mes_ano_label)         AS meses_com_uso,
    SUM(f.valor_brl)                        AS total_gasto_brl,
    MIN(d.data_completa)                    AS primeira_transacao,
    MAX(d.data_completa)                    AS ultima_transacao

FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_COLABORADOR      c ON f.sk_colaborador = c.sk_colaborador
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa     = e.sk_empresa
JOIN dbo.DIM_DATA             d ON f.sk_data        = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status      = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY c.colaborador_id, e.razao_social, e.porte, c.status_colaborador
ORDER BY total_transacoes_historico desc;
GO

REALIZADO VS META
-- ============================================================
 
-- B1. MRR Realizado vs Meta por produto e mês
--     Usa a tabela 02_caju_receita_mensal via staging ou view
--     Aqui demonstrado com os dados do Star Schema + meta hardcoded
--     Em produção: substituir os valores de meta por tabela DIM_META
WITH realizado AS (
    SELECT
        d.mes_ano_label,
        p.linha                             AS produto,
        e.porte,
        SUM(f.valor_brl)                    AS receita_realizada_brl,
        COUNT(DISTINCT f.sk_empresa)        AS empresas_ativas
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
    JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
    JOIN dbo.DIM_EMPRESA e ON f.sk_empresa = e.sk_empresa
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label, p.linha, e.porte
),
meta AS (
    -- Substitua por JOIN com tabela de metas quando disponível
    SELECT mes_ano_label, produto, porte,
           receita_realizada_brl * 1.10 AS meta_brl   -- meta = +10% sobre realizado anterior
    FROM realizado
)
SELECT
    r.mes_ano_label,
    r.produto,
    r.porte,
    r.receita_realizada_brl,
    m.meta_brl,
    r.receita_realizada_brl - m.meta_brl        AS gap_brl,
    CAST(
        100.0 * r.receita_realizada_brl
        / NULLIF(m.meta_brl, 0)
    AS DECIMAL(5,1))                            AS atingimento_pct,
    CASE
        WHEN r.receita_realizada_brl >= m.meta_brl THEN 'Acima da Meta'
        WHEN r.receita_realizada_brl >= m.meta_brl * 0.9 THEN 'Próximo da Meta'
        ELSE 'Abaixo da Meta'
    END                                         AS status_meta
FROM realizado r
JOIN meta m
    ON r.mes_ano_label = m.mes_ano_label
    AND r.produto      = m.produto
    AND r.porte        = m.porte
ORDER BY r.mes_ano_label DESC, gap_brl ASC;
GO
 
 
-- B2. Evolução mês a mês — crescimento MoM (Month over Month)
--     Insight: identifica meses de aceleração ou desaceleração

 
 
-- B3. Acumulado no ano (YTD) vs Meta anual por empresa
--     Insight: onde concentrar esforço de CS para fechar o ano
SELECT
    e.empresa_id,
    e.razao_social,
    e.porte,
    e.gestor_cs,
    SUM(f.valor_brl)                        AS receita_ytd_brl,
    e.mrr_brl * 12                          AS arr_contratado_brl,
    CAST(
        100.0 * SUM(f.valor_brl)
        / NULLIF(e.mrr_brl * 12, 0)
    AS DECIMAL(5,1))                        AS pct_consumido_do_arr,
    e.mrr_brl * 12 - SUM(f.valor_brl)      AS saldo_arr_a_consumir
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa = e.sk_empresa
JOIN dbo.DIM_DATA             d ON f.sk_data    = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status  = s.sk_status
WHERE s.is_aprovada = 1
  AND d.ano = YEAR(GETDATE())
GROUP BY e.empresa_id, e.razao_social, e.porte, e.gestor_cs, e.mrr_brl
ORDER BY saldo_arr_a_consumir DESC;
GO
 
 
-- ============================================================
--  BLOCO C — COLABORADORES DESLIGADOS + ANÁLISE DE USO
-- ============================================================
 
-- Colaboradores inativos/bloqueados que ainda consumiram benefício
-- Hipótese: uso após desligamento = risco financeiro e compliance
SELECT
    c.colaborador_id,
    c.status_colaborador,
    e.razao_social                          AS empresa,
    e.gestor_cs,
    MIN(d.data_completa)                    AS primeiro_uso,
    MAX(d.data_completa)                    AS ultimo_uso_registrado,
    COUNT(*)                                AS transacoes_apos_desligamento,
    SUM(f.valor_brl)                        AS total_gasto_irregular_brl
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_COLABORADOR      c ON f.sk_colaborador = c.sk_colaborador
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa     = e.sk_empresa
JOIN dbo.DIM_DATA             d ON f.sk_data        = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status      = s.sk_status
WHERE c.status_colaborador IN ('Inativo', 'Bloqueado')
  AND s.is_aprovada         = 1
  AND d.data_completa       > c.data_ativacao   -- usou após data de ativação original
GROUP BY c.colaborador_id, c.status_colaborador,
         e.razao_social, e.gestor_cs, c.data_ativacao
HAVING SUM(f.valor_brl) > 0
ORDER BY total_gasto_irregular_brl DESC;
GO
 
 
-- C2. Colaboradores com baixo uso (menos de 2 transações no último mês)
--     Insight: candidatos a intervenção de engajamento pelo CS
WITH uso_recente AS (
    SELECT
        f.sk_colaborador,
        COUNT(*) AS transacoes_ultimo_mes
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada   = 1
      AND d.mes_ano_label = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM')
    GROUP BY f.sk_colaborador
)
SELECT
    c.colaborador_id,
    e.razao_social                              AS empresa,
    e.porte,
    e.gestor_cs,
    c.status_colaborador,
    c.produto_principal,
    COALESCE(u.transacoes_ultimo_mes, 0)        AS transacoes_ultimo_mes,
    CASE
        WHEN u.transacoes_ultimo_mes IS NULL    THEN 'Sem uso'
        WHEN u.transacoes_ultimo_mes < 2        THEN 'Uso crítico'
        WHEN u.transacoes_ultimo_mes < 5        THEN 'Uso baixo'
        ELSE 'Uso normal'
    END                                         AS classificacao_engajamento
FROM dbo.DIM_COLABORADOR c
JOIN dbo.DIM_EMPRESA e ON c.empresa_id = e.empresa_id
LEFT JOIN uso_recente u ON c.sk_colaborador = u.sk_colaborador
WHERE c.status_colaborador = 'Ativo'
ORDER BY transacoes_ultimo_mes ASC, e.razao_social;
GO
 
 
-- C3. Heatmap de uso: mês x categoria para identificar sazonalidade
--     Insight: Alimentação sobe em dezembro? Mobilidade cai no inverno?
SELECT
    d.mes_ano_label,
    d.mes_nome,
    p.categoria_produto,
    COUNT(*)                                AS qtd_transacoes,
    COUNT(DISTINCT f.sk_colaborador)        AS colaboradores_unicos,
    SUM(f.valor_brl)                        AS total_brl,
    AVG(f.valor_brl)                        AS ticket_medio
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY d.mes_ano_label, d.mes_nome, p.categoria_produto
ORDER BY d.mes_ano_label, total_brl DESC;
GO
 
 
-- ============================================================
--  BLOCO D — HIPÓTESES DE MERCADO / PERGUNTAS ESTRATÉGICAS
-- ============================================================
 
-- D1. Empresas em risco de churn (baixo engajamento + NPS baixo)
--     Hipótese: empresa com menos de 40% dos colaboradores usando = risco
WITH uso_empresa AS (
    SELECT
        f.sk_empresa,
        COUNT(DISTINCT f.sk_colaborador)    AS colaboradores_que_usaram,
        SUM(f.valor_brl)                    AS total_gasto_brl,
        MAX(d.data_completa)                AS ultima_transacao
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada   = 1
      AND d.mes_ano_label >= FORMAT(DATEADD(MONTH, -3, GETDATE()), 'yyyy-MM')
    GROUP BY f.sk_empresa
),
total_colaboradores AS (
    SELECT empresa_id, COUNT(*) AS total_colab
    FROM dbo.DIM_COLABORADOR
    WHERE status_colaborador = 'Ativo'
    GROUP BY empresa_id
)
SELECT
    e.empresa_id,
    e.razao_social,
    e.porte,
    e.gestor_cs,
    e.status_cliente,
    e.mrr_brl,
    tc.total_colab,
    COALESCE(u.colaboradores_que_usaram, 0) AS colaboradores_que_usaram,
    CAST(
        100.0 * COALESCE(u.colaboradores_que_usaram, 0)
        / NULLIF(tc.total_colab, 0)
    AS DECIMAL(5,1))                        AS taxa_adocao_pct,
    COALESCE(u.total_gasto_brl, 0)         AS gasto_90dias_brl,
    u.ultima_transacao,
    DATEDIFF(DAY, u.ultima_transacao, GETDATE()) AS dias_sem_transacao,
    CASE
        WHEN COALESCE(u.colaboradores_que_usaram,0) = 0             THEN 'CRITICO - Sem uso'
        WHEN 100.0 * u.colaboradores_que_usaram
             / NULLIF(tc.total_colab,0) < 40                        THEN 'RISCO - Baixa adoção'
        WHEN 100.0 * u.colaboradores_que_usaram
             / NULLIF(tc.total_colab,0) < 70                        THEN 'ATENCAO - Adoção média'
        ELSE 'SAUDAVEL'
    END                                     AS saude_conta
FROM dbo.DIM_EMPRESA e
JOIN total_colaboradores tc  ON e.empresa_id = tc.empresa_id
LEFT JOIN uso_empresa u      ON e.sk_empresa = u.sk_empresa
WHERE e.status_cliente = 'Ativo'
ORDER BY taxa_adocao_pct ASC, e.mrr_brl DESC;
GO
 
 
-- D2. Produto com maior taxa de negação por segmento
--     Hipótese: taxa alta de negação = fricção de UX ou política mal configurada
SELECT
    e.segmento,
    p.linha                                 AS produto,
    p.categoria_produto,
    COUNT(*)                                AS total_tentativas,
    SUM(CASE WHEN s.status_transacao = 'Aprovada'  THEN 1 ELSE 0 END) AS aprovadas,
    SUM(CASE WHEN s.status_transacao = 'Negada'    THEN 1 ELSE 0 END) AS negadas,
    SUM(CASE WHEN s.status_transacao = 'Estornada' THEN 1 ELSE 0 END) AS estornadas,
    CAST(
        100.0 * SUM(CASE WHEN s.status_transacao = 'Negada' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(5,2))                        AS taxa_negacao_pct,
    CAST(
        100.0 * SUM(CASE WHEN s.status_transacao = 'Estornada' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(5,2))                        AS taxa_estorno_pct
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa = e.sk_empresa
JOIN dbo.DIM_PRODUTO          p ON f.sk_produto = p.sk_produto
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status  = s.sk_status
GROUP BY e.segmento, p.linha, p.categoria_produto
HAVING COUNT(*) > 10
ORDER BY taxa_negacao_pct DESC;
GO
 
 
-- D3. LTV estimado por porte de empresa (valor gerado ao longo da relação)
--     Hipótese: Enterprise tem LTV > 10x SMB?
WITH historico AS (
    SELECT
        e.empresa_id,
        e.razao_social,
        e.porte,
        e.data_contrato,
        SUM(f.valor_brl)                    AS receita_total_historica,
        DATEDIFF(MONTH,
            e.data_contrato,
            GETDATE())                      AS meses_como_cliente,
        COUNT(DISTINCT d.mes_ano_label)     AS meses_com_receita
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa = e.sk_empresa
    JOIN dbo.DIM_DATA             d ON f.sk_data    = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status  = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY e.empresa_id, e.razao_social, e.porte, e.data_contrato
)
SELECT
    porte,
    COUNT(*)                                AS qtd_empresas,
    AVG(receita_total_historica)            AS ltv_medio_brl,
    MAX(receita_total_historica)            AS ltv_maximo_brl,
    MIN(receita_total_historica)            AS ltv_minimo_brl,
    AVG(meses_como_cliente)                 AS longevidade_media_meses,
    AVG(receita_total_historica
        / NULLIF(meses_com_receita,0))      AS mrr_medio_realizado_brl
FROM historico
GROUP BY porte
ORDER BY ltv_medio_brl DESC;
GO
 
 
-- D4. Concentração de receita — regra 80/20 (Pareto)
--     Hipótese: 20% das empresas geram 80% da receita?
WITH receita_por_empresa AS (
    SELECT
        e.empresa_id,
        e.razao_social,
        e.porte,
        SUM(f.valor_brl)                    AS receita_total
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa = e.sk_empresa
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status  = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY e.empresa_id, e.razao_social, e.porte
),
ranking AS (
    SELECT *,
        SUM(receita_total) OVER ()                          AS receita_grand_total,
        SUM(receita_total) OVER (ORDER BY receita_total DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS receita_acumulada,
        ROW_NUMBER() OVER (ORDER BY receita_total DESC)     AS rank_receita
    FROM receita_por_empresa
)
SELECT
    rank_receita,
    empresa_id,
    razao_social,
    porte,
    receita_total,
    CAST(100.0 * receita_total
         / NULLIF(receita_grand_total, 0) AS DECIMAL(5,2))  AS pct_receita,
    CAST(100.0 * receita_acumulada
         / NULLIF(receita_grand_total, 0) AS DECIMAL(5,2))  AS pct_acumulado
FROM ranking
ORDER BY rank_receita;
GO
 
 
-- D5. Canal de uso: App vs Físico vs Online — distribuição por porte
--     Hipótese: Enterprise usa mais o canal físico; SMB é mais digital?
SELECT
    e.porte,
    l.canal_transacao,
    COUNT(*)                                AS qtd_transacoes,
    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY e.porte)
    AS DECIMAL(5,1))                        AS pct_dentro_porte,
    SUM(f.valor_brl)                        AS total_brl
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa  = e.sk_empresa
JOIN dbo.DIM_LOCALIDADE       l ON f.sk_localidade = l.sk_localidade
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status   = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY e.porte, l.canal_transacao
ORDER BY e.porte, qtd_transacoes DESC;
GO
 
 
-- ============================================================
--  BLOCO E — QUERIES EXPORTAÇÃO PARA EXCEL
--  Cada query gera uma aba específica para análise
-- ============================================================
 
-- EXCEL_TAB_1: "Gastos por Benefício"
--  ? Tabela dinâmica: linha = Mês, coluna = Categoria, valor = Total R$
SELECT
    d.mes_ano_label                         AS [Mês],
    d.ano                                   AS [Ano],
    d.trimestre                             AS [Trimestre],
    e.porte                                 AS [Porte Empresa],
    e.segmento                              AS [Segmento],
    p.linha                                 AS [Produto Caju],
    p.categoria_produto                     AS [Categoria Benefício],
    l.canal_transacao                       AS [Canal],
    l.estado                                AS [Estado],
    COUNT(*)                                AS [Qtd Transações],
    COUNT(DISTINCT f.sk_colaborador)        AS [Colaboradores Ativos],
    COUNT(DISTINCT f.sk_empresa)            AS [Empresas],
    SUM(f.valor_brl)                        AS [Total Gasto R$],
    AVG(f.valor_brl)                        AS [Ticket Médio R$],
    SUM(CASE WHEN s.is_aprovada=1 THEN f.valor_brl ELSE 0 END) AS [Gasto Aprovado R$],
    SUM(CASE WHEN s.status_transacao='Negada' THEN 1 ELSE 0 END) AS [Qtd Negadas]
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_DATA             d ON f.sk_data       = d.sk_data
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa    = e.sk_empresa
JOIN dbo.DIM_PRODUTO          p ON f.sk_produto    = p.sk_produto
JOIN dbo.DIM_LOCALIDADE       l ON f.sk_localidade = l.sk_localidade
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status     = s.sk_status
GROUP BY
    d.mes_ano_label, d.ano, d.trimestre,
    e.porte, e.segmento,
    p.linha, p.categoria_produto,
    l.canal_transacao, l.estado
ORDER BY d.mes_ano_label, p.categoria_produto;
GO
 
 
-- EXCEL_TAB_2: "Realizado vs Meta"
--  ? Gráfico de barras agrupadas + linha de meta
WITH realizado AS (
    SELECT
        d.mes_ano_label,
        p.linha,
        e.porte,
        SUM(f.valor_brl)    AS receita_brl
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
    JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
    JOIN dbo.DIM_EMPRESA e ON f.sk_empresa = e.sk_empresa
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label, p.linha, e.porte
)
SELECT
    r.mes_ano_label                         AS [Mês],
    r.linha                                 AS [Produto],
    r.porte                                 AS [Porte],
    r.receita_brl                           AS [Realizado R$],
    ROUND(r.receita_brl * 1.10, 2)         AS [Meta R$ (+10%)],
    ROUND(r.receita_brl - r.receita_brl * 1.10, 2)  AS [Gap R$],
    CAST(100.0 * r.receita_brl
         / NULLIF(r.receita_brl * 1.10, 0)
         AS DECIMAL(5,1))                   AS [Atingimento %],
    CASE
        WHEN r.receita_brl >= r.receita_brl * 1.10 THEN 'Acima'
        WHEN r.receita_brl >= r.receita_brl * 0.95 THEN 'Próximo'
        ELSE 'Abaixo'
    END                                     AS [Status Meta]
FROM realizado r
ORDER BY r.mes_ano_label, r.linha, r.porte;
GO
 
 
-- EXCEL_TAB_3: "Evolução Mensal"
--  ? Gráfico de linha: MRR mês a mês com MoM%
SELECT
    d.mes_ano_label                         AS [Mês],
    d.ano                                   AS [Ano],
    d.mes_numero                            AS [Nº Mês],
    p.linha                                 AS [Produto],
    SUM(f.valor_brl)                        AS [Receita R$],
    COUNT(DISTINCT f.sk_empresa)            AS [Empresas Ativas],
    COUNT(DISTINCT f.sk_colaborador)        AS [Colaboradores Ativos],
    COUNT(*)                                AS [Total Transações],
    LAG(SUM(f.valor_brl))
        OVER (PARTITION BY p.linha
              ORDER BY d.mes_ano_label)     AS [Receita Mês Anterior R$],
    CAST(
        100.0 * (SUM(f.valor_brl)
            - LAG(SUM(f.valor_brl))
                OVER (PARTITION BY p.linha ORDER BY d.mes_ano_label))
        / NULLIF(LAG(SUM(f.valor_brl))
                OVER (PARTITION BY p.linha ORDER BY d.mes_ano_label), 0)
    AS DECIMAL(5,1))                        AS [Crescimento MoM %]
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY d.mes_ano_label, d.ano, d.mes_numero, p.linha
ORDER BY p.linha, d.mes_ano_label;
GO
 
 
-- EXCEL_TAB_4: "Saúde dos Colaboradores"
--  ? Tabela de colaboradores p/ filtrar desligados, inativos e baixo uso
SELECT
    c.colaborador_id                        AS [ID Colaborador],
    e.razao_social                          AS [Empresa],
    e.porte                                 AS [Porte],
    e.segmento                              AS [Segmento],
    e.gestor_cs                             AS [Gestor CS],
    c.status_colaborador                    AS [Status],
    c.produto_principal                     AS [Produto Principal],
    c.data_ativacao                         AS [Data Ativação],
    COUNT(f.sk_transacao)                   AS [Total Transações],
    COALESCE(SUM(f.valor_brl), 0)           AS [Total Gasto R$],
    COALESCE(MAX(d.data_completa), NULL)    AS [Última Transação],
    DATEDIFF(DAY,
        MAX(d.data_completa),
        GETDATE())                          AS [Dias sem Uso],
    CASE
        WHEN c.status_colaborador <> 'Ativo'                        THEN 'Desligado'
        WHEN COUNT(f.sk_transacao) = 0                              THEN 'Nunca usou'
        WHEN DATEDIFF(DAY, MAX(d.data_completa), GETDATE()) > 60    THEN 'Uso crítico'
        WHEN DATEDIFF(DAY, MAX(d.data_completa), GETDATE()) > 30    THEN 'Uso baixo'
        ELSE 'Engajado'
    END                                     AS [Classificação Engajamento]
FROM dbo.DIM_COLABORADOR c
JOIN dbo.DIM_EMPRESA e
    ON c.empresa_id = e.empresa_id
LEFT JOIN dbo.FACT_TRANSACAO f
    ON c.sk_colaborador = f.sk_colaborador
LEFT JOIN dbo.DIM_DATA d
    ON f.sk_data = d.sk_data
LEFT JOIN dbo.DIM_STATUS_TRANSACAO s
    ON f.sk_status = s.sk_status
   AND s.is_aprovada = 1
GROUP BY
    c.colaborador_id, e.razao_social, e.porte, e.segmento,
    e.gestor_cs, c.status_colaborador, c.produto_principal, c.data_ativacao
ORDER BY [Dias sem Uso] DESC;
GO
 
 
-- EXCEL_TAB_5: "Distribuição por Estado"
--  ? Gráfico de pizza/mapa: onde está concentrado o GMV
SELECT
    l.estado                                AS [Estado],
    l.regiao                                AS [Região],
    p.linha                                 AS [Produto],
    COUNT(*)                                AS [Qtd Transações],
    COUNT(DISTINCT f.sk_empresa)            AS [Empresas],
    COUNT(DISTINCT f.sk_colaborador)        AS [Colaboradores],
    SUM(f.valor_brl)                        AS [GMV R$],
    CAST(
        100.0 * SUM(f.valor_brl)
        / SUM(SUM(f.valor_brl)) OVER ()
    AS DECIMAL(5,2))                        AS [% do GMV Total]
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_LOCALIDADE       l ON f.sk_localidade = l.sk_localidade
JOIN dbo.DIM_PRODUTO          p ON f.sk_produto    = p.sk_produto
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status     = s.sk_status
WHERE s.is_aprovada = 1
GROUP BY l.estado, l.regiao, p.linha
ORDER BY [GMV R$] DESC;
GO