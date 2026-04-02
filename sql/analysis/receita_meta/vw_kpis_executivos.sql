USE Caju_dw;
GO

CREATE VIEW dbo.vw_kpis_executivos AS

WITH mrr_mensal AS (
    SELECT
        d.mes_ano_label,
        d.ano,
        d.trimestre,
        SUM(f.valor_brl) AS mrr_total_brl,
        SUM(f.valor_brl) * 12 AS arr_brl,
        COUNT(DISTINCT f.sk_empresa) AS clientes_ativos,
        COUNT(DISTINCT f.sk_colaborador) AS colaboradores_ativos,
        COUNT(*) AS total_transacoes,
        SUM(f.valor_brl) AS gmv_brl
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label, d.ano, d.trimestre
),
meta_mensal AS (
    SELECT
        mes_ano_label,
        mrr_total_brl,
        LAG(mrr_total_brl) OVER (ORDER BY mes_ano_label) * 1.10 AS meta_mrr_brl
    FROM mrr_mensal
),
mrr_atual AS (
    SELECT
        mes_ano_label,
        mrr_total_brl
    FROM mrr_mensal
    WHERE mes_ano_label = (SELECT MAX(mes_ano_label) FROM mrr_mensal)
),
churn_mensal AS (
    SELECT
        d.mes_ano_label,
        f.sk_empresa
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d
        ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s
        ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label, f.sk_empresa
),
churn_calc AS (
    SELECT
        atual.mes_ano_label,
        -- empresas que tinham receita no mês anterior
        -- mas NÃO têm no mês atual = churn real
        COUNT(DISTINCT anterior.sk_empresa)     AS empresas_churned,
        COUNT(DISTINCT anterior_base.sk_empresa) AS base_anterior,
        CAST(
            100.0
            * COUNT(DISTINCT anterior.sk_empresa)
            / NULLIF(COUNT(DISTINCT anterior_base.sk_empresa), 0)
        AS DECIMAL(5,2))                         AS churn_rate_pct
    FROM (
        SELECT DISTINCT mes_ano_label
        FROM churn_mensal
    ) atual
    -- base do mês anterior
    LEFT JOIN churn_mensal anterior_base
        ON anterior_base.mes_ano_label = FORMAT(
            DATEADD(MONTH, -1,
                CAST(atual.mes_ano_label + '-01' AS DATE)
            ), 'yyyy-MM'
        )
    -- empresas que saíram = estavam no anterior mas não estão no atual
    LEFT JOIN churn_mensal anterior
        ON  anterior.sk_empresa = anterior_base.sk_empresa
        AND anterior.mes_ano_label = anterior_base.mes_ano_label
        AND NOT EXISTS (
            SELECT 1 FROM churn_mensal atual_emp
            WHERE atual_emp.sk_empresa   = anterior.sk_empresa
              AND atual_emp.mes_ano_label = atual.mes_ano_label
        )
    GROUP BY atual.mes_ano_label
),
novos_clientes AS (
    -- Empresa é "nova" no mês em que aparece pela primeira vez
    SELECT
        d.mes_ano_label,
        COUNT(*) AS novos_clientes
    FROM (
        SELECT
            f.sk_empresa,
            MIN(d2.mes_ano_label) AS primeiro_mes
        FROM dbo.FACT_TRANSACAO f
        JOIN dbo.DIM_DATA d2 ON f.sk_data = d2.sk_data
        GROUP BY f.sk_empresa
    ) primeira_vez
    JOIN dbo.DIM_DATA d ON d.mes_ano_label = primeira_vez.primeiro_mes
    GROUP BY d.mes_ano_label
),
nrr_calc AS (
    -- NRR real = receita dos clientes existentes no mês atual vs
    -- receita desses mesmos clientes no mês anterior
    SELECT
        atual.mes_ano_label,
        CAST(
            100.0
            * SUM(CASE
                WHEN anterior.sk_empresa IS NOT NULL
                THEN atual.valor_brl
                ELSE 0
              END)
            / NULLIF(SUM(CASE
                WHEN anterior.sk_empresa IS NOT NULL
                THEN anterior.valor_brl
                ELSE NULL
              END), 0)
        AS DECIMAL(5,2))                AS nrr_pct
    FROM (
        SELECT f.sk_empresa, d.mes_ano_label, SUM(f.valor_brl) AS valor_brl
        FROM dbo.FACT_TRANSACAO f
        JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
        JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
        WHERE s.is_aprovada = 1
        GROUP BY f.sk_empresa, d.mes_ano_label
    ) atual
    LEFT JOIN (
        SELECT f.sk_empresa, d.mes_ano_label, SUM(f.valor_brl) AS valor_brl
        FROM dbo.FACT_TRANSACAO f
        JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
        JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
        WHERE s.is_aprovada = 1
        GROUP BY f.sk_empresa, d.mes_ano_label
    ) anterior
        ON  atual.sk_empresa   = anterior.sk_empresa
        AND anterior.mes_ano_label = FORMAT(
                DATEADD(MONTH, -1,
                    CAST(atual.mes_ano_label + '-01' AS DATE)
                ), 'yyyy-MM'
            )
    GROUP BY atual.mes_ano_label
)

SELECT
    m.mes_ano_label                             AS mes_ref,
    ROUND(m.mrr_total_brl, 2)                   AS mrr_total_brl,
    ROUND(m.arr_brl, 2)                         AS arr_brl,
    ROUND(mt.meta_mrr_brl, 2)                   AS meta_mrr_brl,
    CAST(
        100.0 * m.mrr_total_brl
        / NULLIF(mt.meta_mrr_brl, 0)
    AS DECIMAL(5,2))                            AS atingimento_pct,
    COALESCE(ch.churn_rate_pct, 0)             AS churn_rate_pct,
    COALESCE(nr.nrr_pct, 100)                  AS nrr_pct,
    COALESCE(nc.novos_clientes, 0)             AS novos_clientes,
    m.clientes_ativos,
    m.colaboradores_ativos,
    m.gmv_brl,
    m.total_transacoes
FROM mrr_mensal m
LEFT JOIN meta_mensal    mt ON m.mes_ano_label = mt.mes_ano_label
LEFT JOIN churn_calc     ch ON m.mes_ano_label = ch.mes_ano_label
LEFT JOIN nrr_calc       nr ON m.mes_ano_label = nr.mes_ano_label
LEFT JOIN novos_clientes nc ON m.mes_ano_label = nc.mes_ano_label;
GO

-- ============================================================
--  VALIDAR A VIEW
-- ============================================================
SELECT * FROM dbo.vw_kpis_executivos ORDER BY mes_ref;
GO