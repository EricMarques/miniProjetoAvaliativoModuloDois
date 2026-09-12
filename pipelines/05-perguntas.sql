-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 04-fato.sql
--
--  Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--  aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--  Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--  de loja. AVG ignora NULL - por isso a etapa nao cumprida foi gravada como NULL.
--  dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

-- >>> ESCREVA AQUI a consulta da P1
SELECT
    dl.porte,
    ROUND(AVG(fp.dias_integracao_separacao), 1) AS media_integracao_separacao,
    ROUND(AVG(fp.dias_separacao_nota), 1) AS media_separacao_nota,
    ROUND(AVG(fp.dias_nota_despacho), 1) AS media_nota_despacho,
    ROUND(AVG(fp.dias_despacho_entrega), 1) AS media_despacho_entrega,
    ROUND(AVG(fp.dias_total_ate_entrega), 1) AS media_total_ate_entrega
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
GROUP BY dl.porte
ORDER BY dl.porte;


-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--  PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--  subconsulta com o faturamento da rede como denominador.

-- >>> ESCREVA AQUI a consulta da P2
SELECT
    dc.nome_categoria,
    dc.grupo_categoria,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento,
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido fp
JOIN dim_categoria dc ON dc.sk_categoria = fp.sk_categoria
GROUP BY dc.nome_categoria, dc.grupo_categoria
ORDER BY faturamento DESC;


-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- >>> ESCREVA AQUI a consulta da P3
SELECT
    canal_pedido,
    ROUND(SUM(vl_liquido) / COUNT(*), 2) AS ticket_medio_geral,
    ROUND(SUM(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END) / 
          NULLIF(COUNT(CASE WHEN houve_desconto = 'Sim' THEN 1 END), 0), 2) AS ticket_com_desconto,
    ROUND(SUM(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END) / 
          NULLIF(COUNT(CASE WHEN houve_desconto = 'Nao' THEN 1 END), 0), 2) AS ticket_sem_desconto,
    ROUND(100 * SUM(vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_faturamento
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY percentual_do_faturamento DESC;


-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_praca e a ponte.
--  Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--  entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--  praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--  nao ser contado duas vezes.

-- >>> ESCREVA AQUI a consulta da P4
SELECT
    dp.nome_praca,
    dp.regional,
    dp.domicilios_com_pet,
    ROUND(SUM(fp.vl_liquido * bp.fator_publico), 2) AS faturamento_rateado,
    ROUND(100 * SUM(fp.vl_liquido * bp.fator_publico) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
JOIN bridge_loja_praca bp ON bp.cod_loja = dl.cod_loja
JOIN dim_praca dp ON dp.sk_praca = bp.sk_praca
GROUP BY dp.sk_praca, dp.nome_praca, dp.regional, dp.domicilios_com_pet
ORDER BY faturamento_rateado DESC;


-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
SELECT
    dl.nome_loja,
    dl.cidade,
    dl.populacao_cidade,
    COUNT(fp.sk_pedido) AS itens_totais,
    ROUND(1000 * COUNT(fp.sk_pedido) / dl.populacao_cidade, 2) AS itens_por_mil_hab,
    ROUND(AVG(fp.dias_total_ate_entrega), 1) AS tempo_medio_entrega_dias
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
WHERE fp.sk_loja <> -1
GROUP BY dl.sk_loja, dl.nome_loja, dl.cidade, dl.populacao_cidade
ORDER BY itens_por_mil_hab DESC;


--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
SELECT
    dl.faixa_franquia,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento,
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total,
    COUNT(DISTINCT dl.sk_loja) AS numero_de_lojas
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
WHERE fp.sk_loja <> -1
GROUP BY dl.faixa_franquia
ORDER BY faturamento DESC;


--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.
SELECT
    'pedidos sem loja identificada' AS o_que_ficou_de_fora,
    COUNT(*) AS quantidade,
    ROUND(SUM(vl_liquido), 2) AS faturamento
FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT
    'entregas ainda nao concluidas',
    COUNT(*),
    ROUND(SUM(vl_liquido), 2)
FROM fato_pedido WHERE sk_tempo_entrega = -1
UNION ALL SELECT
    'itens em branco ou zero',
    COUNT(*),
    ROUND(SUM(vl_liquido), 2)
FROM fato_pedido WHERE qt_itens IS NULL
UNION ALL SELECT
    'valores em branco ou zero',
    COUNT(*),
    ROUND(SUM(vl_liquido), 2)
FROM fato_pedido WHERE vl_liquido IS NULL;
