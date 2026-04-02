# Analise de Receita de Indicadores - Cartão Benefícios


## Visão Geral
Este projeto nasceu na necessidade de corrigir e estruturar indicadores de receita recorrente (MRR,ARR,Churn,Atingimento) que estava inconsistentes e dificultavam a tomada de descisão.
O mercado costuma trabalhar com dados inflados ou acumulados, o que gera decisões equivocadas sobre metas, investimentos e expansão.
O objetivo central foi criar um *Dashboard Executivo Confiável*, capaz de responder ás principais perguntas de negócio: 
 - **Estamos crescendo de forma saudável?**
 - **Qual é a receita anual recorrente projetada, o negócio está sendo sustentado no ritmo atual?**
 - **O time comercial está performando e estamos atingindo nossas metas de receita?**
 - **Estamos perdendo clientes?**
 - **Quais segmentos de clientes sustentam o MRR?**
 - **Quais linhas de produto são mais relevantes e qual merece mais investimento?**
 - **Qual é a eficiência de aquisição por segmento?**
  
## Objetivos do Projeto
- Calcular corretamente MRR e ARR.
- Validar métricas de atingimento de metas e churn.
- Construir visualizações estratégicas em Power BI.
- Gerar insights diferenciados para apoiar decisões executivas.
  
##  Estrutura do Repositório
- `/sql` → scripts SQL.
- `/data_raw` → dados brutos.
- `/docs` → documentação complementar:
  - `modelagem_dimensional.pdf` → Relacionamneto de Tabelas.
  - `dicionario_dados.md` → dicionário de dados.
  - `arquitetura_projeto.md` → arquitetura do pipeline.
  - `business_insights.md` → insights estratégicos.
- `/dashboard` → arquivos do Power BI ou exportações.

## Modelagem dos dados em StarSchema
A Modelagem completa está disponível em (https://miro.com/app/board/uXjVGpQlsa4=/?share_link_id=957359051559)

##  Dicionário de Dados
O dicionário completo está disponível em [`docs/dicionario_dados.md`](docs/dicionario_dados.md).

##  Dashboard
Principais visualizações:
- MRR Total vs Meta
- ARR Total
- Atingimento da Meta
- Taxa de Churn
- Distribuição por porte de cliente
- Distribuição por linha de produto
- LTV/CAC por segmento
- LINK:(https://app.powerbi.com/links/N3a3WCeXsx?ctid=14cbd5a7-ec94-46ba-b314-cc0fc972a161&pbi_source=linkShare)
- *Todos os dados foram validados em comparação a base Original, Consultas SQl e código Dax.*

##  Insights Estratégicos
- Atingimento de metas em 83,7%:
Entrega resultado mas tem um gap de 16,7 prescisa ser investigado.

- SMB domina 43% da receita:
O segmento de entrada sustenta o crescimento. Fidelização e decisão executiva em Volume/Valor são chave para manter essa base saudável. [Saiba mais no link de insight](docs/insights_negocio.md)

- Produtos equilibrados, mas sem destaque: 
A linha está bem distribuída, mas falta um “carro-chefe” que concentre demanda e acelere crescimento.

- Churn zerado: 
A retenção está funcionando. O desafio agora é escalar sem perder essa vantagem competitiva.

- Segmentação clara, mas com espaço para afinar ICP e foco:  
Mid-Market é o ponto ótimo hoje. Enterprise tem potencial, mas exige retenção longa e CAC controlado.
- Insights com mais detalhes dísponivel em [`docs/insights_negocio.md`](docs/insights_negocio.md)
