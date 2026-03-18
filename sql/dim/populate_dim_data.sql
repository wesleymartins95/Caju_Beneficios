--  STEP 3 — POPULAR DIM_DATA
--  Gera todas as datas cobertas pelas transações do CSV
--  (abordagem de calendar table gerada via CTE recursiva)
-------------------------------------------------------------

WITH datas_range AS (
    -- pega o intervalo de datas existente nas transações
    SELECT
        CAST(MIN(data_transacao) AS DATE) AS dt_inicio,
        CAST(MAX(data_transacao) AS DATE) AS dt_fim
    FROM dbo.STG_TRANSACOES
),
calendario AS (
    SELECT dt_inicio AS dt FROM datas_range
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM calendario
    WHERE dt < (SELECT dt_fim FROM datas_range)
)
INSERT INTO dbo.DIM_DATA (
    sk_data,
    data_completa,
    ano,
    trimestre,
    mes_numero,
    mes_nome,
    semana_ano,
    dia_mes,
    dia_semana_numero,
    dia_semana_nome,
    is_fim_semana,
    mes_ano_label
)
SELECT
    -- sk_data como inteiro no formato YYYYMMDD (padrão DW)
    CAST(FORMAT(dt, 'yyyyMMdd') AS INT)         AS sk_data,
    dt                                          AS data_completa,
    YEAR(dt)                                    AS ano,
    DATEPART(QUARTER, dt)                       AS trimestre,
    MONTH(dt)                                   AS mes_numero,
    DATENAME(MONTH, dt)                         AS mes_nome,
    DATEPART(ISO_WEEK, dt)                      AS semana_ano,
    DAY(dt)                                     AS dia_mes,
    DATEPART(WEEKDAY, dt)                       AS dia_semana_numero,
    DATENAME(WEEKDAY, dt)                       AS dia_semana_nome,
    CASE WHEN DATEPART(WEEKDAY, dt) IN (1,7)
         THEN 1 ELSE 0 END                      AS is_fim_semana,
    FORMAT(dt, 'yyyy-MM')                       AS mes_ano_label
FROM calendario
-- evita duplicata em re-execuções
WHERE CAST(FORMAT(dt, 'yyyyMMdd') AS INT)
      NOT IN (SELECT sk_data FROM dbo.DIM_DATA)
OPTION (MAXRECURSION 3650);  -- suporta até ~10 anos de datas
GO