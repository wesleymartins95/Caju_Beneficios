USE Caju_dw;
GO

CREATE VIEW dbo.ytd_vs_meta AS
WITH receita_mensal AS (
    SELECT
        d.ano,
        d.mes_ano_label,
        p.linha                             AS produto,
        SUM(f.valor_brl)                    AS receita_brl
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
    JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.ano, d.mes_ano_label, p.linha
),
ytd AS (
    SELECT
        ano,
        mes_ano_label,
        produto,
        SUM(receita_brl) OVER (
            PARTITION BY ano, produto
            ORDER BY mes_ano_label
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS receita_ytd_brl
    FROM receita_mensal
),
meta_anual AS (
    -- Em produção: substituir por tabela DIM_META
    SELECT
        ano,
        produto,
        SUM(receita_brl) * 1.10 AS meta_anual_brl   -- Exemplo: meta = +10% sobre receita do ano anterior
    FROM receita_mensal
    GROUP BY ano, produto
)
SELECT
    y.ano,
    y.mes_ano_label,
    y.produto,
    y.receita_ytd_brl,
    m.meta_anual_brl,
    y.receita_ytd_brl - m.meta_anual_brl AS gap_brl,
    CAST(100.0 * y.receita_ytd_brl / NULLIF(m.meta_anual_brl,0) AS DECIMAL(5,1)) AS atingimento_pct,
    CASE
        WHEN y.receita_ytd_brl >= m.meta_anual_brl THEN 'Acima da Meta'
        WHEN y.receita_ytd_brl >= m.meta_anual_brl * 0.9 THEN 'Próximo da Meta'
        ELSE 'Abaixo da Meta'
    END AS status_meta
FROM ytd y
JOIN meta_anual m
    ON y.ano = m.ano
    AND y.produto = m.produto;
GO
