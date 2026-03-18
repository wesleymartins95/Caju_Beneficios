-- Gasto por ÁREA (segmento de empresa) e tipo de benefício
--     Insight: qual segmento mais usa qual produto
USE Caju_dw
GO

USE Caju_dw;
GO

CREATE VIEW dbo.vw_gasto_area_categoria AS
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
GO
