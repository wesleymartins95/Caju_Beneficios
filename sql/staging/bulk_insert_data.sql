--  STEP 2 — BULK INSERT: CSV / STAGING
-----------------------------------------------------

-- 2.1 Clientes
BULK INSERT dbo.STG_CLIENTES
FROM 'C:\Users\wesle\github\portfolio_projetos\caju\01_caju_clientes.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,          -- pula o cabeçalho
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',    -- UTF-8
    TABLOCK
);

-- 2.2 Colaboradores
BULK INSERT dbo.STG_COLABORADORES
FROM 'C:\Users\wesle\github\portfolio_projetos\caju\03_caju_colaboradores.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

-- 2.3 Transações
BULK INSERT dbo.STG_TRANSACOES
FROM 'C:\Users\wesle\github\portfolio_projetos\caju\04_caju_transacoes.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);
GO