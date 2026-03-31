# 📚 Dicionário de Dados — Cartão Benefícios

> Projeto de análise de receita e engajamento.  
> Dados simulados para fins de estudo e desenvolvimento de dashboards.  
> Stack: SQL Server 2021 · Power BI Desktop 2.152 · MIRO- Star Schema

---

## 📁 Estrutura dos arquivos

```
data/
├── 01_caju_clientes.csv          →  10 linhas   · Base de empresas clientes
├── 02_caju_receita_mensal.csv    →  48 linhas   · MRR por produto e mês
├── 03_caju_colaboradores.csv     → 200 linhas   · Usuários dos produtos Caju
├── 04_caju_transacoes.csv        → 1000 linhas  · Transações individuais
├── 05_caju_pipeline_comercial.csv →  80 linhas  · Oportunidades de venda
├── 06_caju_churn_expansao.csv    → 120 linhas   · Movimentos de MRR
├── 07_caju_kpis_executivos.csv   →  12 linhas   · KPIs agregados por mês
└── 08_caju_nps_saude.csv         →  60 linhas   · NPS e saúde por cliente
```

---

## 01 · `caju_clientes.csv`

**Descrição:** Base cadastral das empresas clientes da Caju. Cada linha representa uma empresa contratante.  
**Chave primária:** `empresa_id`  
**Conecta com:** `03_colaboradores`, `04_transacoes`, `06_churn_expansao`, `08_nps_saude`

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `empresa_id` | `string` | Identificador único da empresa. Formato: `E001`–`E010` | `E001` |
| `razao_social` | `string` | Nome legal da empresa | `Tech Nova Ltda` |
| `segmento` | `string` | Setor de atuação da empresa | `Tecnologia`, `Varejo`, `Saúde` |
| `porte` | `string` | Tamanho da empresa. Valores: `SMB`, `Mid-Market`, `Enterprise` | `Enterprise` |
| `cidade` | `string` | Cidade sede da empresa | `São Paulo` |
| `estado` | `string` | UF da empresa. Formato: sigla de 2 letras | `SP` |
| `data_contrato` | `date` | Data de início do contrato com a Caju. Formato: `YYYY-MM-DD` | `2022-03-15` |
| `mrr_brl` | `decimal` | Valor mensal recorrente **contratado** em R$. Representa o ARR ÷ 12 | `48000.00` |
| `status` | `string` | Situação atual do cliente. Valores: `Ativo`, `Churn`, `Em Risco` | `Ativo` |
| `gestor_cs` | `string` | Nome do Customer Success responsável pela conta | `Ana Lima` |
| `nps_ultimo` | `integer` | Último NPS registrado. Escala 0–100 | `72` |

> **Nota:** `mrr_brl` representa o valor **contratado** — diferente do MRR **realizado** calculado nas transações. A diferença entre os dois é o indicador de adoção da conta.

---

## 02 · `caju_receita_mensal.csv`

**Descrição:** Receita mensal agregada por produto. Base para análise de Realizado vs. Meta e crescimento MoM.  
**Chave composta:** `mes_ref` + `produto`  
**Conecta com:** `07_kpis_executivos`

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `mes_ref` | `string` | Mês de referência. Formato: `YYYY-MM` | `2024-07` |
| `produto` | `string` | Nome do produto Caju | `Cartão Multi Benefícios` |
| `receita_realizada_brl` | `decimal` | MRR efetivamente realizado no mês em R$ | `1053226.07` |
| `meta_brl` | `decimal` | Meta de MRR definida para o mês em R$ | `1050000.00` |
| `num_empresas_ativas` | `integer` | Quantidade de empresas com receita no mês | `262` |
| `ticket_medio_brl` | `decimal` | Receita média por empresa ativa. Fórmula: `receita_realizada ÷ num_empresas_ativas` | `4019.95` |
| `churn_receita_brl` | `decimal` | MRR perdido por cancelamentos no mês em R$ | `12216.14` |
| `expansao_brl` | `decimal` | MRR ganho por expansão de contas existentes em R$ | `59859.64` |
| `new_biz_brl` | `decimal` | MRR gerado por novas empresas no mês em R$ | `68016.33` |

> **Produtos disponíveis:** `Cartão Multi Benefícios` · `Despesas Corporativas` · `Premiações` · `Caju Ciclos`

---

## 03 · `caju_colaboradores.csv`

**Descrição:** Base de usuários finais (colaboradores das empresas clientes). Cada linha é um colaborador ativo ou inativo.  
**Chave primária:** `colaborador_id`  
**Conecta com:** `01_clientes` via `empresa_id`, `04_transacoes` via `colaborador_id`

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `colaborador_id` | `string` | Identificador único do colaborador. Formato: `C0001`–`C0200` | `C0001` |
| `empresa_id` | `string` | FK para `01_clientes`. Empresa empregadora | `E004` |
| `produto` | `string` | Produto Caju principal do colaborador | `Caju Ciclos` |
| `data_ativacao` | `date` | Data de ativação do cartão/produto. Formato: `YYYY-MM-DD` | `2023-07-09` |
| `status` | `string` | Situação do colaborador. Valores: `Ativo`, `Inativo`, `Bloqueado` | `Ativo` |
| `saldo_disponivel_brl` | `decimal` | Saldo atual disponível no cartão em R$ | `821.32` |
| `gasto_mes_brl` | `decimal` | Total gasto no mês corrente em R$. Zero para inativos | `777.39` |
| `categoria_gasto` | `string` | Categoria predominante de uso | `Home Office`, `Alimentação`, `Saúde` |
| `frequencia_uso_mensal` | `integer` | Quantidade de transações realizadas no mês. Zero para inativos | `20` |

> **Categorias disponíveis:** `Alimentação` · `Refeição` · `Mobilidade` · `Saúde` · `Educação` · `Home Office` · `Cultura` · `Flex`

---

## 04 · `caju_transacoes.csv`

**Descrição:** Registro granular de cada transação realizada pelos colaboradores. É a tabela fato central do modelo Star Schema.  
**Chave primária:** `transacao_id`  
**Conecta com:** todas as dimensões via chaves estrangeiras

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `transacao_id` | `string` | Identificador único da transação. Formato: `T000001`–`T001000` | `T000001` |
| `colaborador_id` | `string` | FK para `03_colaboradores` | `C0200` |
| `empresa_id` | `string` | FK para `01_clientes` | `E005` |
| `data_transacao` | `date` | Data da transação. Formato: `YYYY-MM-DD` | `2025-07-15` |
| `produto` | `string` | Produto Caju utilizado na transação | `Cartão Multi Benefícios` |
| `categoria` | `string` | Categoria do gasto | `Home Office` |
| `valor_brl` | `decimal` | Valor da transação em R$ | `770.14` |
| `status_transacao` | `string` | Resultado da transação. Valores: `Aprovada`, `Negada`, `Estornada` | `Aprovada` |
| `canal` | `string` | Canal utilizado. Valores: `App`, `Físico`, `Online` | `Físico` |
| `cidade` | `string` | Cidade onde a transação ocorreu | `Rio de Janeiro` |
| `estado` | `string` | UF da transação | `RJ` |

> **Distribuição de status:** ~88% Aprovada · ~9% Negada · ~3% Estornada  
> **Período:** últimos 365 dias a partir da data de geração

---

## 05 · `caju_pipeline_comercial.csv`

**Descrição:** Oportunidades de venda em andamento. Base para análise de funil, conversão e projeção de receita futura.  
**Chave primária:** `oportunidade_id`  
**Não conecta com outras tabelas** — dados de prospects ainda não clientes

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `oportunidade_id` | `string` | Identificador da oportunidade. Formato: `OPP0001`–`OPP0080` | `OPP0001` |
| `empresa_prospect` | `string` | Nome da empresa em negociação | `Empresa Prospect 1` |
| `segmento` | `string` | Setor de atuação do prospect | `Financeiro` |
| `porte` | `string` | Tamanho do prospect. Valores: `SMB`, `Mid-Market`, `Enterprise` | `SMB` |
| `produto_interesse` | `string` | Produto de interesse do prospect | `Premiações` |
| `estagio_funil` | `string` | Etapa atual no funil de vendas | `Proposta` |
| `valor_arr_estimado_brl` | `decimal` | ARR estimado do contrato em R$ | `180000.00` |
| `probabilidade_pct` | `integer` | Probabilidade de fechamento em %. Varia por estágio | `50` |
| `vendedor` | `string` | Nome do vendedor responsável | `Beatriz Silva` |
| `data_entrada_funil` | `date` | Data de entrada no pipeline. Formato: `YYYY-MM-DD` | `2025-12-07` |
| `data_prevista_fechamento` | `date` | Data estimada de fechamento. Formato: `YYYY-MM-DD` | `2026-07-05` |
| `origem_lead` | `string` | Canal de origem do lead | `Evento`, `Inbound`, `Outbound` |

> **Estágios do funil:** `Prospecção` (15%) · `Qualificação` (30%) · `Proposta` (50%) · `Negociação` (70%) · `Ganho` (100%) · `Perdido` (0%)

---

## 06 · `caju_churn_expansao.csv`

**Descrição:** Registro de movimentos de MRR — entradas, saídas e expansões por empresa. Base para o gráfico Waterfall de MRR.  
**Chave composta:** `empresa_id` + `mes_ref` + `evento`  
**Conecta com:** `01_clientes` via `empresa_id`

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `empresa_id` | `string` | FK para `01_clientes` | `E001` |
| `mes_ref` | `string` | Mês do evento. Formato: `YYYY-MM` | `2025-06` |
| `evento` | `string` | Tipo de movimento de MRR | `Expansão` |
| `mrr_antes_brl` | `decimal` | MRR da empresa antes do evento em R$ | `5797.64` |
| `mrr_depois_brl` | `decimal` | MRR da empresa após o evento em R$ | `7169.99` |
| `delta_brl` | `decimal` | Variação de MRR. Positivo = crescimento · Negativo = perda | `1372.35` |
| `motivo` | `string` | Razão do evento | `Renegociação`, `Preço`, `Competidor` |
| `produto` | `string` | Produto afetado pelo evento | `Cartão Multi Benefícios` |
| `porte` | `string` | Porte da empresa no momento do evento | `SMB` |

> **Tipos de evento:** `Churn` · `Contração` · `Expansão` · `Upsell` · `Reativação`  
> **Motivos de churn:** `Preço` · `Fit produto` · `Competidor` · `Crise interna` · `Sem uso`  
> **Motivos de expansão:** `Novos colaboradores` · `Novo produto` · `Renegociação` · `Campanha`

---

## 07 · `caju_kpis_executivos.csv`

**Descrição:** KPIs de negócio agregados mensalmente. Visão executiva da saúde financeira da Caju. Equivale à `vw_kpis_executivos` no SQL Server.  
**Chave primária:** `mes_ref`  
**Atenção:** `ltv_brl` e `ltv_cac_ratio` contêm valores simulados incorretos — use as medidas DAX para esses indicadores.

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `mes_ref` | `string` | Mês de referência. Formato: `YYYY-MM` | `2024-07` |
| `mrr_total_brl` | `decimal` | MRR realizado no mês em R$ | `1682071.73` |
| `arr_brl` | `decimal` | ARR projetado. Fórmula: `mrr_total × 12` | `20184860.76` |
| `meta_mrr_brl` | `decimal` | Meta de MRR definida para o mês em R$ | `1790250.00` |
| `atingimento_pct` | `decimal` | % de atingimento da meta. Fórmula: `mrr_total ÷ meta × 100` | `93.96` |
| `churn_rate_pct` | `decimal` | Taxa de churn mensal em %. Empresas perdidas ÷ base anterior | `1.55` |
| `nrr_pct` | `decimal` | Net Revenue Retention em %. Acima de 100% = expansão líquida | `113.38` |
| `cac_brl` | `decimal` | Custo de Aquisição de Cliente médio em R$ ⚠️ simulado | `2653.28` |
| `ltv_brl` | `decimal` | Lifetime Value médio em R$ ⚠️ valor incorreto — usar DAX | `1302249081.29` |
| `ltv_cac_ratio` | `decimal` | Ratio LTV ÷ CAC ⚠️ valor incorreto — usar DAX | `490807.26` |
| `novos_clientes` | `integer` | Novas empresas ativas no mês | `16` |
| `clientes_ativos` | `integer` | Total de empresas com receita no mês | `368` |
| `nps_medio` | `integer` | NPS médio da base no mês. Escala 0–100 | `60` |
| `gmv_brl` | `decimal` | Gross Merchandise Value — volume bruto transacionado em R$ | `14897192.30` |

> **Benchmark de mercado SaaS B2B:**  
> `churn_rate_pct` saudável: abaixo de 2% ao mês  
> `nrr_pct` saudável: acima de 110%  
> `ltv_cac_ratio` saudável: acima de 3×

---

## 08 · `caju_nps_saude.csv`

**Descrição:** Indicadores de saúde e satisfação por empresa e mês. Base para o radar de risco do CS.  
**Chave composta:** `empresa_id` + `mes_ref`  
**Conecta com:** `01_clientes` via `empresa_id`

| Coluna | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `empresa_id` | `string` | FK para `01_clientes` | `E001` |
| `mes_ref` | `string` | Mês de referência. Formato: `YYYY-MM` | `2025-01` |
| `nps_score` | `integer` | NPS da empresa no mês. Escala 0–100 | `19` |
| `categoria_nps` | `string` | Classificação do NPS. Valores: `Promotor` (≥70) · `Neutro` (50–69) · `Detrator` (<50) | `Detrator` |
| `health_score` | `decimal` | Score de saúde da conta 0–100. Combina uso, NPS e tickets | `59.3` |
| `ticket_abertos` | `integer` | Quantidade de chamados abertos no mês | `12` |
| `tempo_medio_resolucao_h` | `decimal` | Tempo médio de resolução de tickets em horas | `35.5` |
| `onboarding_completo` | `boolean` | Se o onboarding foi concluído. Valores: `True` · `False` | `True` |
| `engajamento_colaboradores_pct` | `decimal` | % de colaboradores que usaram o produto no mês | `57.3` |
| `produto_principal` | `string` | Produto de maior uso na empresa no mês | `Despesas Corporativas` |

> **Referência health_score:** acima de 70 = Saudável · 40–70 = Atenção · abaixo de 40 = Crítico

---

## 🔗 Mapa de relacionamentos

```
01_clientes ──────────────────────────────────────────┐
    empresa_id (PK)                                    │
         │                                             │
         ├──→ 03_colaboradores (empresa_id FK)         │
         │         │                                   │
         │         └──→ 04_transacoes (colaborador_id FK)
         │                    │
         ├──→ 04_transacoes (empresa_id FK)            │
         │                                             │
         ├──→ 06_churn_expansao (empresa_id FK)        │
         │                                             │
         └──→ 08_nps_saude (empresa_id FK) ────────────┘

02_receita_mensal ──→ 07_kpis_executivos (mes_ref)
05_pipeline ─────────── standalone (prospects)
```

---

## ⚙️ Stack técnica

| Camada | Tecnologia |
|---|---|
| Armazenamento | SQL Server 2021 |
| Modelagem | Miro Star Schema — 1 Fato + 6 Dimensões |
| Transformação | Views SQL (`vw_kpis_executivos`, `vw_saude_carteira`) |
| Visualização | Power BI Desktop 2.152 (março/2026) |
| Linguagem analítica | DAX (medidas de apresentação) |
| Exportação | CSV UTF-8 separado por vírgula |

---

## ⚠️ Limitações dos dados simulados

- Valores de `ltv_brl` e `ltv_cac_ratio` no arquivo `07` estão incorretos — gerados com fórmula inadequada. Use as medidas DAX `LTV Estimado` e `LTV CAC Ratio` no Power BI.
- O `mrr_brl` em `01_clientes` representa contrato simulado sem correlação direta com as transações de `04_transacoes`.
- Base de 10 empresas e 200 colaboradores — escala reduzida para fins didáticos.
- Dados gerados aleatoriamente sem sazonalidade real.