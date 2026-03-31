# Arquitetura do Projeto Cartão Benefício - Receita e Indicadores

## 📖 Visão Geral
Este documento descreve a arquitetura do projeto de análise de receita recorrente.  
O objetivo é detalhar como os dados são coletados, transformados, modelados e apresentados em dashboards executivos.

---

## 🗂️ Componentes Principais

### 1. Fonte de Dados
- Tabelas Operacionais
  - `FACT_TRANSACAO` → transações financeiras (valor, status, data).
  - `DIM_EMPRESA` → informações de clientes (porte, segmento).
  - `DIM_DATA` → calendário de referência.
  - `DIM_STATUS_TRANSACAO` → status de aprovação.

### 2. Camada de Modelagem
- View Principal `vw_kpis_executivos`
  - KPIs calculados MRR, ARR, Atingimento, Churn, NRR.
  - Correções aplicadas  
    - ARR = MRR × 12 (mês atual).  
    - Atingimento filtrado pelo mês mais recente.  
    - Churn validado com base em clientes ativos.

### 3. Medidas DAX
- `MRR Total por Porte`
- `ARR Total`
- `% Atingimento Atual`
- `Taxa de Churn`
- Medidas auxiliares para gráficos (Pareto, LTVCAC).

### 4. Camada de Visualização (Power BI)
- KPIs em Cards MRR, ARR, Atingimento, Churn.
- Gráficos
  - MRR vs Meta mensal.
  - MRR por porte de cliente.
  - MRR por linha de produto.
  - % Atingimento por produto.
  - LTVCAC por segmento.

---

## 🔄 Fluxo de Dados

1. Ingestão dados extraídos das tabelas operacionais.  
2. Transformação: criação da view `vw_kpis_executivos` com cálculos corrigidos.  
3. Modelagem medidas DAX aplicadas para métricas executivas.  
4. Visualização dashboards em Power BI para análise estratégica.  

---

## 🧩 Governança e Documentação
- README.md → visão geral do projeto.
- docs/modelagem_star_schema.pdf → Relacionamentos entre Tabelas. 
- docs/dicionario_dados.md → dicionário de dados (tabelas, colunas, tipos, regras).  
- docs/arquitetura_projeto.txt.md → arquitetura e fluxo de dados.  
- docs/insights_negocio.md → insights estratégicos e recomendações.  

---

## 🎯 Benefícios da Arquitetura
- KPIs confiáveis e consistentes.  
- Estrutura clara para manutenção e evolução.  
- Suporte à tomada de decisão executiva com dados reais.  
- Documentação organizada para onboarding de novos analistas.
