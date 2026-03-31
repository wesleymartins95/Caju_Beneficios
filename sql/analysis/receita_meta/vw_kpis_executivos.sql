USE Caju_dw;
GO

CREATE VIEW dbo.vw_kpis_executivos AS

WITH mrr_mensal AS (
    SELECT
        d.mes_ano_label,
        d.ano,
        d.trimestre,
        SUM(e.mrr_brl) AS mrr_total_brl,
        SUM(e.mrr_brl) * 12 AS arr_brl,
        COUNT(DISTINCT f.sk_empresa) AS clientes_ativos,
        COUNT(DISTINCT f.sk_colaborador) AS colaboradores_ativos,
        COUNT(*) AS total_transacoes,
        SUM(f.valor_brl) AS gmv_brl
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    JOIN dbo.DIM_EMPRESA e ON f.sk_empresa = e.sk_empresa
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
        COUNT(DISTINCT f.sk_empresa) AS empresas_mes
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA d ON f.sk_data = d.sk_data
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label
),
churn_calc AS (
    SELECT
        c.mes_ano_label,
        c.empresas_mes,
        LAG(c.empresas_mes) OVER (ORDER BY c.mes_ano_label) AS empresas_mes_anterior,
        CAST(
            100.0 * (LAG(c.empresas_mes) OVER (ORDER BY c.mes_ano_label) - c.empresas_mes)
            / NULLIF(LAG(c.empresas_mes) OVER (ORDER BY c.mes_ano_label), 0)
        AS DECIMAL(5,2)) AS churn_rate_pct
    FROM churn_mensal c
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
    -- NRR = Receita mês atual de clientes existentes / Receita deles no mês anterior
    SELECT
        atual.mes_ano_label,
        CAST(
            100.0 * atual.mrr_total_brl
            / NULLIF(anterior.mrr_total_brl, 0)
        AS DECIMAL(5,2)) AS nrr_pct
    FROM mrr_mensal atual
    LEFT JOIN mrr_mensal anterior
        ON anterior.mes_ano_label = FORMAT(
            DATEADD(MONTH, -1,
                CAST(atual.mes_ano_label + '-01' AS DATE)
            ), 'yyyy-MM'
        )
)

SELECT
    m.mes_ano_label                         AS mes_ref,
    m.mrr_total_brl,
    m.arr_brl,
    mt.meta_mrr_brl,
    CAST(
        100.0 * m.mrr_total_brl
        / NULLIF(mt.meta_mrr_brl, 0)
    AS DECIMAL(5,2))                        AS atingimento_pct,
    COALESCE(ch.churn_rate_pct, 0)         AS churn_rate_pct,
    COALESCE(nr.nrr_pct, 100)             AS nrr_pct,
    COALESCE(nc.novos_clientes, 0)         AS novos_clientes,
    m.clientes_ativos,
    m.colaboradores_ativos,
    m.gmv_brl,
    m.total_transacoes
FROM mrr_mensal m
LEFT JOIN meta_mensal   mt ON m.mes_ano_label = mt.mes_ano_label
LEFT JOIN churn_calc    ch ON m.mes_ano_label = ch.mes_ano_label
LEFT JOIN nrr_calc      nr ON m.mes_ano_label = nr.mes_ano_label
LEFT JOIN novos_clientes nc ON m.mes_ano_label = nc.mes_ano_label;
GO

-- ============================================================
--  VALIDAR A VIEW
-- ============================================================
SELECT * FROM dbo.vw_kpis_executivos ORDER BY mes_ref;
GO