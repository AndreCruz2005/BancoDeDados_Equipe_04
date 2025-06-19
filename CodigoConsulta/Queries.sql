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


-- Encontra a idade mínima, média e máxima de pessoas por tipo, mais as datas de nascimento da mais velha e nova pessoa por tipo.
DECLARE
    TYPE AgeData IS RECORD (
        v_min_age NUMBER(4, 1),
        v_avg_age NUMBER(4, 1),
        v_max_age NUMBER(4, 1)
    );

    TYPE AgeDataTable IS TABLE OF AgeData INDEX BY Pessoa.TIPO%TYPE;

    v_age_data_table AgeDataTable;

    pessoaTipo Pessoa.TIPO%TYPE;
    currRow AgeData;

    CURSOR c_datas IS
        SELECT tipo, 
        MIN((SYSDATE - DATA_NASCIMENTO) / 365.25), 
        AVG((SYSDATE - DATA_NASCIMENTO) / 365.25), 
        MAX((SYSDATE - DATA_NASCIMENTO) / 365.25)
        FROM Pessoa
        GROUP BY tipo;
BEGIN
    OPEN c_datas;
    LOOP
        FETCH c_datas INTO pessoaTipo, currRow.v_min_age, currRow.v_avg_age, currRow.v_max_age;
        EXIT WHEN c_datas%NOTFOUND;

        v_age_data_table(pessoaTipo) := currRow;
    END LOOP;
    CLOSE c_datas;

    pessoaTipo := v_age_data_table.FIRST;
    WHILE pessoaTipo IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Tipo: ' || pessoaTipo ||
            ' | Menor Idade: ' || TO_CHAR(v_age_data_table(pessoaTipo).v_min_age) ||
            ' | Idade Média: ' || TO_CHAR(v_age_data_table(pessoaTipo).v_avg_age) ||
            ' | Maior Idade: ' || TO_CHAR(v_age_data_table(pessoaTipo).v_max_age) ||
            ' | Aniversário mais recente: ' || TO_CHAR(SYSDATE - v_age_data_table(pessoaTipo).v_min_age * 365.25, 'DD/MM/YYYY') ||
            ' | Aniversário mais antigo: ' || TO_CHAR(SYSDATE - v_age_data_table(pessoaTipo).v_max_age * 365.25, 'DD/MM/YYYY')
        );
        pessoaTipo := v_age_data_table.NEXT(pessoaTipo);
    END LOOP;
END;
/

-- Relatório sobre exumações que incluí o jazigo original e o jazigo de destino
SELECT
    (SELECT nome FROM Pessoa WHERE id = fal.id) AS nome,
    (SELECT jazigo_id FROM Exumacao WHERE falecido_id = fal.id) AS jazigo_original,
    (SELECT jazigo_id from Sepultamento WHERE falecido_id = fal.id) AS jazigo_destino
FROM Falecido fal
WHERE fal.id IN (
    SELECT falecido_id
    FROM Exumacao
);


--  Seleciona funcionários não coveiros que recebem menos que algum coveiro
SELECT p.nome, f.data_contratacao, f.funcao, f.salario FROM FUNCIONARIO f
JOIN Pessoa p ON p.id = f.id
WHERE salario < ANY (
    SELECT salario FROM Funcionario WHERE funcao = 'Coveiro'
)
AND Funcao != 'Coveiro';


-- Seleciona jazigos com capacidade maior do que o total de sepultamentos em qualquer jazigo
SELECT * FROM Jazigo
WHERE capacidade > ALL (
    SELECT COUNT(*)
    FROM Sepultamento
    GROUP BY jazigo_id
);
