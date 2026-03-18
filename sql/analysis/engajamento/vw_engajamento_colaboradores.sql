USE Caju_dw;
GO

-- Criação da view de ranking de engajamento dos colaboradores
CREATE VIEW dbo.vw_engajamento_colaboradores AS
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
GROUP BY c.colaborador_id, e.razao_social, e.porte, c.status_colaborador;
GO
