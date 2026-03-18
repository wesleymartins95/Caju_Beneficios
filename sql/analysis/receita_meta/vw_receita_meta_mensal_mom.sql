USE Caju_dw;
GO

CREATE VIEW dbo.vw_receita_meta_mensal_mom AS
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
    -- Em produção: substituir por JOIN com tabela DIM_META
    SELECT mes_ano_label, produto, porte,
           receita_realizada_brl * 1.10 AS meta_brl   -- meta = +10% sobre realizado anterior
    FROM realizado
),
comparacao AS (
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
        END                                         AS status_meta,
        LAG(r.receita_realizada_brl) OVER (
            PARTITION BY r.produto, r.porte
            ORDER BY r.mes_ano_label
        ) AS receita_mes_anterior
    FROM realizado r
    JOIN meta m
        ON r.mes_ano_label = m.mes_ano_label
        AND r.produto      = m.produto
        AND r.porte        = m.porte
)
SELECT
    mes_ano_label,
    produto,
    porte,
    receita_realizada_brl,
    meta_brl,
    gap_brl,
    atingimento_pct,
    status_meta,
    receita_mes_anterior,
    receita_realizada_brl - receita_mes_anterior AS variacao_abs_brl,
    CAST(
        100.0 * (receita_realizada_brl - receita_mes_anterior)
        / NULLIF(receita_mes_anterior, 0)
    AS DECIMAL(5,1)) AS crescimento_mom_pct
FROM comparacao;
GO
