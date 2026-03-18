-- Colaboradores com baixo uso (menos de 2 transações no último mês)
--     Insight: candidatos a intervenção de engajamento pelo CS

USE Caju_dw;
GO

CREATE VIEW dbo.vw_colaboradores_baixo_uso AS
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
GO
