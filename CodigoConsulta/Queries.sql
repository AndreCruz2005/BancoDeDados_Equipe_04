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

-- Relatório sobre a Capaciade dos Jazigos
SELECT 
j.id, j.tipo, j.capacidade, 
(SELECT COUNT(*) from SEPULTAMENTO WHERE JAZIGO_ID = j.id) AS sepultamentos
FROM JAZIGO j;

