-- C3. Heatmap de uso: mês x categoria para identificar sazonalidade
--     Insight: Alimentação sobe em dezembro? Mobilidade cai no inverno?
USE Caju_dw
GO
CREATE VIEW vw_heatmap_uso AS
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
GO