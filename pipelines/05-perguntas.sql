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
    dl.porte as Porte,
    ROUND(AVG(fp.dias_integracao_separacao), 1) AS "Media integração por separação",
    ROUND(AVG(fp.dias_separacao_nota), 1) AS "Media separação por nota",
    ROUND(AVG(fp.dias_nota_despacho), 1) AS "Media de despacho por nota",
    ROUND(AVG(fp.dias_despacho_entrega), 1) AS "Media de despacho por entrega",
    ROUND(AVG(fp.dias_total_ate_entrega), 1) AS "Media de dias até entrega"
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
    dc.nome_categoria AS 'Categoria',
    dc.grupo_categoria AS 'Grupo',
    ROUND(SUM(fp.vl_liquido), 2) AS Faturamento,
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS '% do Total'
FROM fato_pedido fp
JOIN dim_categoria dc ON dc.sk_categoria = fp.sk_categoria
GROUP BY dc.nome_categoria, dc.grupo_categoria
ORDER BY Faturamento DESC;


-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- >>> ESCREVA AQUI a consulta da P3
SELECT
    canal_pedido AS Canal,
    ROUND(SUM(vl_liquido) / COUNT(*), 2) AS "Ticket medio",
    ROUND(SUM(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END) / 
          NULLIF(COUNT(CASE WHEN houve_desconto = 'Sim' THEN 1 END), 0), 2) AS "Ticket médio com desconto",
    ROUND(SUM(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END) / 
          NULLIF(COUNT(CASE WHEN houve_desconto = 'Nao' THEN 1 END), 0), 2) AS "Ticket médio sem desconto",
    ROUND(100 * SUM(vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS "Percentual do faturamento"
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY "Percentual do faturamento" DESC;


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
    dp.nome_praca AS "Praça",
    dp.regional AS "Região",
    dp.domicilios_com_pet AS "Domicílios com animais",
    ROUND(SUM(fp.vl_liquido * bp.fator_publico), 2) AS "Faturamento rateado",
    ROUND(100 * SUM(fp.vl_liquido * bp.fator_publico) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS "Percentual do faturamento"
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
JOIN bridge_loja_praca bp ON bp.cod_loja = dl.cod_loja
JOIN dim_praca dp ON dp.sk_praca = bp.sk_praca
GROUP BY dp.sk_praca, dp.nome_praca, dp.regional, dp.domicilios_com_pet
ORDER BY "Faturamento rateado" DESC;


SELECT
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido) AS "Total da fato",
    (SELECT ROUND(SUM(f.vl_liquido * b.fator_publico)) FROM fato_pedido f
        JOIN dim_loja l ON l.sk_loja = f.sk_loja
        JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja) AS "Total rateado por praça",
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido WHERE sk_loja = -1) AS "Faturamento sem loja",
    ROUND(
        (SELECT SUM(vl_liquido) FROM fato_pedido) -
        (SELECT SUM(f.vl_liquido * b.fator_publico) FROM fato_pedido f
            JOIN dim_loja l ON l.sk_loja = f.sk_loja
            JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja) -
        (SELECT SUM(vl_liquido) FROM fato_pedido WHERE sk_loja = -1)
    ) AS "Diferença";


-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
SELECT
    dl.nome_loja AS "Loja",
    dl.cidade AS "Cidade",
    dl.populacao_cidade AS "População da cidade",
    COUNT(fp.sk_pedido) AS "Itens totais",
    ROUND(1000 * COUNT(fp.sk_pedido) / dl.populacao_cidade,2) AS "Itens por mil habitantes",
    ROUND(AVG(fp.dias_total_ate_entrega),1) AS "Tempo médio de entrega (dias)"
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
WHERE fp.sk_loja <> -1
GROUP BY dl.sk_loja,
		 dl.nome_loja,
         dl.cidade,
         dl.populacao_cidade
ORDER BY "Itens por mil habitantes" DESC;


--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
SELECT
    dl.faixa_franquia AS "Faixa de franquia",
    ROUND(SUM(fp.vl_liquido),2) AS "Faturamento",
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido),2) AS "Percentual do total",
    COUNT(DISTINCT dl.sk_loja) AS "Número de lojas"
FROM fato_pedido fp 
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
WHERE fp.sk_loja <> -1
GROUP BY dl.faixa_franquia
ORDER BY "Faturamento" DESC;


--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.
SELECT
    'Pedidos sem loja identificada' AS "O que ficou de fora",
    COUNT(*) AS "Quantidade",
    ROUND(SUM(vl_liquido), 2) AS "Faturamento"
FROM fato_pedido
WHERE sk_loja = -1
UNION ALL 
SELECT 'Entregas ainda não concluídas',
		COUNT(*),
        ROUND(SUM(vl_liquido), 2)
FROM fato_pedido
WHERE sk_tempo_entrega = -1
UNION ALL 
SELECT 'Itens em branco ou zero',
		COUNT(*),
        ROUND(SUM(vl_liquido), 2)
FROM fato_pedido
WHERE qt_itens IS NULL OR qt_itens = 0
UNION ALL 
SELECT 'Valores em branco ou zero',
		COUNT(*),
        ROUND(SUM(vl_liquido), 2)
FROM fato_pedido
WHERE vl_liquido IS NULL OR vl_liquido = 0;
