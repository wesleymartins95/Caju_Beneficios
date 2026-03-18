-- Colaboradores inativos/bloqueados que ainda consumiram benefício
-- Hipótese: uso após desligamento = risco financeiro e compliance
USE Caju_dw
GO
CREATE VIEW vw_consumo_irregular_colaboradores AS
SELECT
    c.colaborador_id,
    c.status_colaborador,
    e.razao_social                          AS empresa,
    e.gestor_cs,
    MIN(d.data_completa)                    AS primeiro_uso,
    MAX(d.data_completa)                    AS ultimo_uso_registrado,
    COUNT(*)                                AS transacoes_apos_desligamento,
    SUM(f.valor_brl)                        AS total_gasto_irregular_brl
FROM dbo.FACT_TRANSACAO f
JOIN dbo.DIM_COLABORADOR      c ON f.sk_colaborador = c.sk_colaborador
JOIN dbo.DIM_EMPRESA          e ON f.sk_empresa     = e.sk_empresa
JOIN dbo.DIM_DATA             d ON f.sk_data        = d.sk_data
JOIN dbo.DIM_STATUS_TRANSACAO s ON f.sk_status      = s.sk_status
WHERE c.status_colaborador IN ('Inativo', 'Bloqueado')
  AND s.is_aprovada         = 1
  AND d.data_completa       > c.data_ativacao   -- usou após data de ativação original
GROUP BY c.colaborador_id, c.status_colaborador,
         e.razao_social, e.gestor_cs, c.data_ativacao
HAVING SUM(f.valor_brl) > 0
GO