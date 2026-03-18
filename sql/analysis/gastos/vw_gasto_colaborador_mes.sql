-- Insight: identifica top spenders e colaboradores com saldo parado

USE Caju_dw
GO
CREATE VIEW vw_gasto_colaborador_mes AS
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
GO