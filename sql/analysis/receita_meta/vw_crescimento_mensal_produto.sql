-- B2. Evolução mês a mês — crescimento MoM (Month over Month)
--     Insight: identifica meses de aceleração ou desaceleração
USE Caju_dw
GO

-- Criando view de crescimento MoM (Month over Month)

WITH receita_mensal AS (
    SELECT
        d.mes_ano_label,
        p.linha                             AS produto,
        SUM(f.valor_brl)                    AS receita_brl
    FROM dbo.FACT_TRANSACAO f
    JOIN dbo.DIM_DATA    d ON f.sk_data    = d.sk_data
    JOIN dbo.DIM_PRODUTO p ON f.sk_produto = p.sk_produto
    JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status = s.sk_status
    WHERE s.is_aprovada = 1
    GROUP BY d.mes_ano_label, p.linha
)
SELECT
    mes_ano_label,
    produto,
    receita_brl,
    LAG(receita_brl) OVER (PARTITION BY produto ORDER BY mes_ano_label) AS receita_mes_anterior,
    receita_brl
        - LAG(receita_brl) OVER (PARTITION BY produto ORDER BY mes_ano_label) AS variacao_abs_brl,
    CAST(
        100.0 * (receita_brl
            - LAG(receita_brl) OVER (PARTITION BY produto ORDER BY mes_ano_label))
        / NULLIF(LAG(receita_brl) OVER (PARTITION BY produto ORDER BY mes_ano_label), 0)
    AS DECIMAL(5,1))                        AS crescimento_mom_pct
FROM receita_mensal
ORDER BY produto, mes_ano_label;
GO

