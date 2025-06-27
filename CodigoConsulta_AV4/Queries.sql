-- Relatório de Sepultamentos por Período
-- Seleciona informações sobre todos os sepultamentos ocorridos há mais de 5 anos e há menos de 100 anos
-- Informações inclusas: Nome do falecido, data de sepultamento, tipo de sepultamento, tipo de jazigo e localização do jazigo.
-- Mais recente primeiro
SELECT pes.nome, sep.data, sep.tipo, jaz.tipo AS jazigo_tipo, jaz.quadra, jaz.fila, jaz.numero
FROM Sepultamento sep
INNER JOIN Pessoa pes on pes.id = sep.falecido_id
INNER JOIN Jazigo jaz on jaz.id = sep.jazigo_id
WHERE sep.data BETWEEN SYSDATE - (100*365.25) AND SYSDATE - (5*365.25) 
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


-- Seleciona funcionários não coveiros que recebem menos que algum coveiro
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

-- Adiciona coluna para observações nos sepultamentos
ALTER TABLE Sepultamento ADD observacoes VARCHAR2(500);

-- Otimiza buscas por nomes de pessoas e localização de jazigos
CREATE INDEX idx_pessoa_nome ON Pessoa(nome);
CREATE INDEX idx_jazigo_local ON Jazigo(quadra, fila, numero);

-- Aplica reajuste salarial diferenciado por função e tempo de serviço
UPDATE Funcionario f
SET salario = salario * 
    CASE 
        WHEN funcao = 'Administrador' THEN 1.15
        WHEN funcao = 'Atendente' AND MONTHS_BETWEEN(SYSDATE, data_contratacao) > 60 THEN 1.12
        ELSE 1.10
    END
WHERE funcao != 'Coveiro'
AND salario < (
    SELECT MAX(salario) 
    FROM Funcionario 
    WHERE funcao = 'Coveiro'
);

-- Remove solicitações canceladas com mais de 5 anos
DELETE FROM Solicitacao
WHERE status_solicitacao = 'Cancelada'
AND data_solicitacao < ADD_MONTHS(SYSDATE, -60)
AND servico_id NOT IN (
    SELECT id 
    FROM ServicoFunerario 
    WHERE tipo = 'Exumacao'
);

-- Relatório financeiro de serviços por período
SELECT 
    sf.tipo,
    COUNT(*) AS quantidade,
    SUM(sf.valor) AS total,
    AVG(sf.valor) AS media,
    (SELECT nome FROM Pessoa WHERE id = s.funcionario_id) AS responsavel
FROM ServicoFunerario sf
JOIN Solicitacao s ON sf.id = s.servico_id
WHERE sf.data BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') 
                 AND TO_DATE('2023-12-31', 'YYYY-MM-DD')
GROUP BY sf.tipo, s.funcionario_id
HAVING SUM(sf.valor) > 10000
ORDER BY total DESC;

-- Análise de sepultamentos por localização específica
SELECT 
    j.quadra,
    j.fila,
    COUNT(*) AS total_sepultamentos,
    AVG(idade) AS idade_media,
    MAX(idade) AS idade_maxima
FROM (
    SELECT 
        s.jazigo_id,
        TRUNC(MONTHS_BETWEEN(s.data, p.data_nascimento)/12) AS idade
    FROM Sepultamento s
    JOIN Pessoa p ON s.falecido_id = p.id
) sep_idades
JOIN Jazigo j ON sep_idades.jazigo_id = j.id
WHERE j.quadra LIKE 'A%' OR j.quadra LIKE 'BL%'
GROUP BY j.quadra, j.fila
ORDER BY total_sepultamentos DESC;

-- Relatório combinado de falecidos e responsáveis por jazigo
SELECT 
    p.nome AS nome, 
    'Falecido' AS tipo,
    s.data AS data_relevante,
    j.quadra || '-' || j.fila || '-' || j.numero AS localizacao
FROM Pessoa p
JOIN Sepultamento s ON p.id = s.falecido_id
JOIN Jazigo j ON s.jazigo_id = j.id
UNION
SELECT 
    p.nome AS nome,
    'Responsável' AS tipo,
    rj.data_inicio AS data_relevante,
    j.quadra || '-' || j.fila || '-' || j.numero AS localizacao
FROM Pessoa p
JOIN ResponsabilidadeJazigo rj ON p.id = rj.responsavel_id
JOIN Jazigo j ON rj.jazigo_id = j.id
ORDER BY data_relevante DESC;

-- Cria visão detalhada para gestão de jazigos
CREATE VIEW vw_gestao_jazigos AS
SELECT 
    j.id,
    j.quadra,
    j.fila,
    j.numero,
    j.capacidade,
    COUNT(s.falecido_id) AS ocupados,
    j.capacidade - COUNT(s.falecido_id) AS disponiveis,
    (SELECT nome FROM Pessoa WHERE id = rj.responsavel_id) AS responsavel,
    (SELECT MAX(data_inicio) FROM ManutencaoJazigo mj WHERE mj.jazigo_id = j.id) AS ultima_manutencao
FROM Jazigo j
LEFT JOIN Sepultamento s ON j.id = s.jazigo_id
LEFT JOIN ResponsabilidadeJazigo rj ON j.id = rj.jazigo_id
GROUP BY j.id, j.quadra, j.fila, j.numero, j.capacidade, rj.responsavel_id;

-- Exemplos de controle de acesso
/*
GRANT SELECT ON vw_gestao_jazigos TO gestor_cemiterio;
REVOKE DELETE ON Sepultamento FROM atendente;
*/

-- Relatório de jazigos com baixa ocupação
SELECT 
    j.*,
    ocupacao.ocupados,
    (j.capacidade - ocupacao.ocupados) AS disponiveis,
    (SELECT nome FROM Pessoa WHERE id = rj.responsavel_id) AS responsavel
FROM Jazigo j
LEFT JOIN (
    SELECT jazigo_id, COUNT(*) AS ocupados
    FROM Sepultamento
    GROUP BY jazigo_id
) ocupacao ON j.id = ocupacao.jazigo_id
LEFT JOIN ResponsabilidadeJazigo rj ON j.id = rj.jazigo_id
WHERE ocupacao.ocupados < j.capacidade * 0.5
AND j.id IN (
    SELECT jazigo_id 
    FROM Sepultamento 
    WHERE data < ADD_MONTHS(SYSDATE, -60)
);

-- Classificação de funcionários por produtividade
SELECT 
    f.id,
    p.nome,
    f.funcao,
    COUNT(s.id) AS total_solicitacoes,
    CASE 
        WHEN COUNT(s.id) > 20 THEN 'Alta'
        WHEN COUNT(s.id) BETWEEN 10 AND 20 THEN 'Média'
        ELSE 'Baixa'
    END AS produtividade,
    (SELECT SUM(valor) 
     FROM ServicoFunerario sf 
     WHERE sf.id = s.servico_id) AS valor_gerado
FROM Funcionario f
JOIN Pessoa p ON f.id = p.id
LEFT JOIN Solicitacao s ON f.id = s.funcionario_id
GROUP BY f.id, p.nome, f.funcao
HAVING COUNT(s.id) > 0
ORDER BY total_solicitacoes DESC;

-- Atualiza status de jazigos sem manutenção recente
CREATE OR REPLACE PROCEDURE atualizar_jazigos_sem_manutencao AS
    CURSOR c_jazigos IS
        SELECT j.id
        FROM Jazigo j
        WHERE NOT EXISTS (
            SELECT 1
            FROM ManutencaoJazigo mj
            WHERE mj.jazigo_id = j.id
            AND mj.data_inicio > ADD_MONTHS(SYSDATE, -24)
        )
        AND EXISTS (
            SELECT 1
            FROM Sepultamento s
            WHERE s.jazigo_id = j.id
        );
BEGIN
    FOR jazigo IN c_jazigos LOOP
        INSERT INTO ManutencaoJazigo(jazigo_id, funcionario_id, motivo)
        VALUES (jazigo.id, 
               (SELECT id FROM Funcionario WHERE funcao = 'Zelador' AND ROWNUM = 1),
               'Manutenção preventiva programada');
    END LOOP;
    COMMIT;
END atualizar_jazigos_sem_manutencao;
/

-- Calcula tempo médio entre solicitação e conclusão de serviços
CREATE OR REPLACE FUNCTION calcular_tempo_medio_servico
RETURN NUMBER IS
    v_tempo_medio NUMBER;
BEGIN
    SELECT AVG(sf.data - s.data_solicitacao)
    INTO v_tempo_medio
    FROM Solicitacao s
    JOIN ServicoFunerario sf ON s.servico_id = sf.id
    WHERE s.status_solicitacao = 'Concluida';
    
    RETURN v_tempo_medio;
END calcular_tempo_medio_servico;
/

-- Valida capacidade e responsável antes de inserir sepultamento
CREATE OR REPLACE TRIGGER tr_valida_capacidade_jazigo
BEFORE INSERT ON Sepultamento
FOR EACH ROW
DECLARE
    v_ocupacao INT;
    v_capacidade INT;
    v_responsavel INT;
BEGIN
    SELECT j.capacidade, 
           (SELECT COUNT(*) FROM Sepultamento s WHERE s.jazigo_id = :NEW.jazigo_id),
           rj.responsavel_id
    INTO v_capacidade, v_ocupacao, v_responsavel
    FROM Jazigo j
    LEFT JOIN ResponsabilidadeJazigo rj ON j.id = rj.jazigo_id
    WHERE j.id = :NEW.jazigo_id;
    
    IF v_ocupacao >= v_capacidade THEN
        RAISE_APPLICATION_ERROR(-20001, 'Capacidade do jazigo excedida');
    ELSIF v_responsavel IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Jazigo sem responsável designado');
    END IF;
END;
/
