-- Relatório de Sepultamentos por Período
-- Seleciona informações sobre todos os sepultamentos ocorridos há mais de 5 anos e há menos de 100 anos
-- Informações inclusas: Nome do falecido, data de sepultamento, tipo de sepultamento, tipo de jazigo e localização do jazigo.
-- Mais recente primeiro
SELECT pes.nome, sep.data, sep.tipo, jaz.tipo AS jazigo_tipo, jaz.quadra, jaz.fila, jaz.numero
FROM Sepultamento sep
INNER JOIN Pessoa pes on pes.id = sep.falecido_id
INNER JOIN Jazigo jaz on jaz.id = sep.jazigo_id
WHERE data < SYSDATE - (5*365.25) AND data > SYSDATE - (100*365.25) 
ORDER BY data DESC;

-- Relatório sobre a Capacidade dos Jazigos
-- Mostra jazigos com espaço livre restante
-- Exibe ID do Jazigo, tipo, capacidade do jazigo, a quantidade de falecidos sepultados no jazigo e o espaço livre restante
-- Mostra aqueles com mais espaço livre primeiro
SELECT j.id as jazigo_id, j.tipo, j.capacidade, 
    COALESCE(s.qtd, 0) AS sepultamentos,
    j.capacidade - COALESCE(s.qtd, 0) AS espaco_disponivel
FROM 
    Jazigo j
LEFT JOIN (
    SELECT jazigo_id, COUNT(*) AS qtd
    FROM Sepultamento
    GROUP BY jazigo_id
) s ON j.id = s.jazigo_id
ORDER BY espaco_disponivel DESC;

-- Relatório sobre os funcionários que receberam mais solicitações
-- Seleciona somente aqueles que receberam mais de uma solicitação
-- Exibe nome e total de solicitações recebidas pelo funcionário
SELECT pes.nome, COUNT(*) AS total
FROM Solicitacao s
JOIN  Pessoa pes ON pes.id = s.funcionario_id
GROUP BY pes.nome, s.funcionario_id
HAVING COUNT(*) > 1
ORDER BY total DESC;

