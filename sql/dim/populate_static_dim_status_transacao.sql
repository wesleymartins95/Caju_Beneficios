-- Carga estática da dimensão de status
INSERT INTO dbo.DIM_STATUS_TRANSACAO VALUES
(1, 'Aprovada',  NULL,                  1),
(2, 'Negada',    'Saldo insuficiente',  0),
(3, 'Negada',    'Categoria bloqueada', 0),
(4, 'Negada',    'Estabelecimento negado', 0),
(5, 'Estornada', NULL,                  0);
GO