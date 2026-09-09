# Análise de Dados com Python [T2]
## Projeto Avaliativo - Pata Amiga

**Aluno:** Eric Felipe Barros Marques  
**Turma:** Análise de Dados com Python [T2]  

## Sobre o projeto

Este é um mini-projeto avaliativo de análise de dados com Python e SQL.
A Pata Amiga é uma rede catarinense de pet shops com 32 lojas.
O desafio é responder cinco perguntas de negócio usando dados de 4.044 pedidos 
coletados entre setembro de 2023 e março de 2024.

Os dados chegam em três sistemas diferentes, com grafias inconsistentes, 
formatos mistos e relacionamentos complexos.

## Objetivo

Construir um modelo dimensional (estrela) que unifique os dados e permita 
responder:

1. Onde está o gargalo da entrega?
2. Qual categoria concentra o faturamento?
3. O desconto funciona igual em todo canal?
4. Qual praça de atendimento concentra o faturamento?
5. Onde abrir a próxima loja?

## Arquitetura

### Modelo Dimensional

[Aqui vai a imagem do diagrama quando estiver pronto]

Grão da fato: 1 linha = 1 pedido (4.044 linhas)

Dimensões:
- dim_tempo: data em número (20230916)
- dim_loja: cadastro das 32 lojas
- dim_categoria: 7 categorias padronizadas
- dim_praca: 13 praças de atendimento

Bridge:
- bridge_loja_praca: relacionamento N:N com fator de rateio

### Dados de entrada

Três tabelas staging (não alteráveis):
- stg_pedido: 4.044 linhas com os pedidos e marcos de entrega
- stg_loja: 32 linhas com o cadastro das lojas de hoje
- stg_loja_praca: 48 linhas com loja × praça e percentual do público

Deficiências encontradas:
- [Aqui entra o diagnóstico quando rodar as consultas]

## Execução

Para reproduzir o banco do zero, rode os scripts na seguinte ordem:

1. `01-diagnostico.sql` - Valida as tabelas de entrada
2. `02-dimensoes-prontas.sql` - Cria dim_tempo e dim_loja (já vêm prontas)
3. `03-dimensoes-tratadas.sql` - Cria dim_categoria, dim_praca e bridge_loja_praca
4. `04-fato-pedido.sql` - Constrói fato_pedido com 4.044 linhas
5. `05-respostas.sql` - As cinco consultas que respondem as perguntas
6. `00-conferencia.sql` - Valida os números contra os esperados

## Respostas às cinco perguntas

[Aqui entra quando terminar as análises]

### P1: Onde está o gargalo da entrega?

[resposta com número]

### P2: Qual categoria concentra o faturamento?

[resposta com número]

### P3: O desconto funciona igual em todo canal?

[resposta com número]

### P4: Qual praça de atendimento concentra o faturamento?

[resposta com número]

### P5: Onde abrir a próxima loja?

[resposta com número e recomendação]

## Limitações dos dados

[O que os dados NÃO permitem afirmar]

## Tecnologias

- MySQL (banco de dados)
- SQL (tratamento e análise)
