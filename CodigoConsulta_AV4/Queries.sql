-- Otimiza buscas por nomes de pessoas e localização de jazigos
CREATE INDEX idx_pessoa_nome ON Pessoa(nome);
CREATE INDEX idx_jazigo_local ON Jazigo(quadra, fila, numero);

-- (Comandos utilizados: CREATE TRIGGER(Comando), SELECT INTO, CURSOR, FOR LOOP, COUNT, IF)
-- Se um comando de delete for utilizado em Funcionario, remove quaisquer pessoas com tipo funcionario que não têm registro correspondente em Funcionario
CREATE OR REPLACE TRIGGER trg_remove_funcionario
AFTER DELETE ON Funcionario
DECLARE
    v_existe NUMBER;

    CURSOR c_funcionarios IS
        SELECT id FROM Pessoa 
        WHERE TIPO = 'Funcionario';
BEGIN
    FOR fun IN c_funcionarios LOOP
        SELECT COUNT(*) INTO v_existe
        FROM Funcionario 
        WHERE id = fun.id;

        IF v_existe = 0 THEN
            DELETE FROM Pessoa 
            WHERE id = fun.id;
        END IF;
    END LOOP;
END;
/

-- (Comandos utilizados: CREATE TRIGGER(Linha), IF, SELECT INTO)
-- Trigger para impedir que a capacidade de um jazigo seja excedida
CREATE OR REPLACE TRIGGER trg_valida_capacidade_jazigo
BEFORE INSERT ON Sepultamento
FOR EACH ROW
DECLARE
    v_ocupados   INT;
    v_capacidade INT;
BEGIN
    -- Conta quantos falecidos já estão no jazigo
    SELECT COUNT(*) INTO v_ocupados
    FROM Sepultamento
    WHERE jazigo_id = :NEW.jazigo_id;

    -- Obtém a capacidade do jazigo
    SELECT capacidade INTO v_capacidade
    FROM Jazigo
    WHERE id = :NEW.jazigo_id;

    -- Verifica se a capacidade já foi atingida
    IF v_ocupados >= v_capacidade THEN
        RAISE_APPLICATION_ERROR(-20001, 'Capacidade máxima do jazigo atingida.');
    END IF;
END;
/

-- Comandos utilizados: CREATE PACKAGE, Procedure, Function, 
CREATE OR REPLACE PACKAGE pkg_utils IS
    PROCEDURE atualizar_jazigos_sem_manutencao;
    FUNCTION calcular_tempo_medio_servico RETURN NUMBER;
    PROCEDURE atualizar_status_solicitacao ( 
        p_familiar_id       IN Solicitacao.familiar_id%TYPE, 
        p_funcionario_id    IN Solicitacao.funcionario_id%TYPE, 
        p_data_solicitacao  IN Solicitacao.data_solicitacao%TYPE, 
        p_status            IN Solicitacao.status_solicitacao%TYPE, 
        p_msg               IN OUT VARCHAR2, 
        p_sucess            OUT NUMBER 
    ); 
END;

CREATE OR REPLACE PACKAGE BODY pkg_utils IS
    -- Procedimento que atualiza status de jazigos sem manutenção recente
    PROCEDURE atualizar_jazigos_sem_manutencao IS
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

        v_funcionario_id Funcionario.id%TYPE;
    BEGIN
        -- Seleciona um funcionário aleatório
        SELECT id INTO v_funcionario_id
        FROM (
            SELECT id FROM Funcionario ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        -- Faz a inserção para cada jazigo
        FOR jazigo IN c_jazigos LOOP
            INSERT INTO ManutencaoJazigo(jazigo_id, funcionario_id, motivo)
            VALUES (jazigo.id, v_funcionario_id, 'Manutenção preventiva programada');
        END LOOP;

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erro ao atualizar jazigos: ' || SQLERRM);
    END atualizar_jazigos_sem_manutencao;

    -- Função que calcula tempo médio entre solicitação e conclusão de serviços
    FUNCTION calcular_tempo_medio_servico RETURN NUMBER IS
        v_tempo_medio NUMBER;
    BEGIN
        SELECT AVG(sf.data - s.data_solicitacao)
        INTO v_tempo_medio
        FROM Solicitacao s
        JOIN ServicoFunerario sf ON s.servico_id = sf.id
        WHERE s.status_solicitacao = 'Concluida';
        
        RETURN v_tempo_medio;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END calcular_tempo_medio_servico;

    -- (Comandos utilizados: IN, OUT, IN OUT, CREATE PROCEDURE, %TYPE, EXCEPTION)
    -- Procedure para atualizar o status de uma solicitação com validação e error handling
    PROCEDURE atualizar_status_solicitacao ( 
        p_familiar_id       IN Solicitacao.familiar_id%TYPE, 
        p_funcionario_id    IN Solicitacao.funcionario_id%TYPE, 
        p_data_solicitacao  IN Solicitacao.data_solicitacao%TYPE, 
        p_status            IN Solicitacao.status_solicitacao%TYPE, 
        p_msg               IN OUT VARCHAR2, 
        p_sucess            OUT NUMBER 
    ) 
    IS 
        v_status_atual Solicitacao.status_solicitacao%TYPE; 
        v_proximo      Solicitacao.status_solicitacao%TYPE; 
    BEGIN 
        -- Verifica se existe a solicitação e obtém o status atual 
        SELECT status_solicitacao 
        INTO v_status_atual 
        FROM Solicitacao 
        WHERE familiar_id      = p_familiar_id 
        AND funcionario_id   = p_funcionario_id 
        AND data_solicitacao = p_data_solicitacao; 
    
        -- Determina o próximo status válido 
        CASE v_status_atual 
            WHEN 'Pagamento Pendente' THEN v_proximo := 'Em Andamento'; 
            WHEN 'Em Andamento'         THEN v_proximo := 'Concluida'; 
            ELSE v_proximo := NULL; 
        END CASE; 
    
        -- Verifica se a transição solicitada é válida 
        IF p_status = v_proximo THEN 
            -- transição sequencial permitida 
            UPDATE Solicitacao 
            SET status_solicitacao = p_status 
            WHERE familiar_id      = p_familiar_id 
            AND funcionario_id   = p_funcionario_id 
            AND data_solicitacao = p_data_solicitacao; 
    
            p_sucess := 1; 
            p_msg := 'Status atualizado de ' || v_status_atual || ' para ' || p_status; 
    
        ELSIF p_status = 'Cancelada' THEN 
            -- transição para cancelamento sempre permitida 
            UPDATE Solicitacao 
            SET status_solicitacao = p_status 
            WHERE familiar_id      = p_familiar_id 
            AND funcionario_id   = p_funcionario_id 
            AND data_solicitacao = p_data_solicitacao; 
    
            p_sucess := 1; 
            p_msg := 'Solicitação cancelada com sucesso.'; 
    
        ELSE 
            -- transição inválida 
            p_sucess := 0; 
            p_msg := 'Transição de status de "' || v_status_atual || '" para "' || p_status || '" não é permitida.'; 
        END IF; 
    
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            p_sucess := 0; 
            p_msg := 'Solicitação não encontrada.'; 
    
        WHEN OTHERS THEN 
            p_sucess := 0; 
            p_msg := 'Erro: ' || SQLERRM;
    END atualizar_status_solicitacao; 
END pkg_utils;
/

-- (Comandos utilizados: Bloco anônimo)
-- Testa procedures
BEGIN
    pkg_utils.atualizar_jazigos_sem_manutencao;
END;
/
DECLARE
    v_tempo_medio NUMBER;
BEGIN
    v_tempo_medio := ROUND(pkg_utils.calcular_tempo_medio_servico, 3);
    DBMS_OUTPUT.PUT_LINE('Tempo médio: ' || COALESCE(v_tempo_medio, 0) || ' dias');
END;
/

-- (Comandos utlizados: %ROWTYPE, EXCEPTION)
-- Bloco para testar a procedure. Tenta atualizar uma solicitação aleatória para 'Em andamento'
DECLARE
    v_msg VARCHAR2(200);
    v_sucess NUMBER;

    v_solicitacao Solicitacao%ROWTYPE;
BEGIN
    SELECT * INTO v_solicitacao FROM (
        SELECT * 
        FROM Solicitacao
        ORDER BY DBMS_RANDOM.VALUE
    )
    WHERE ROWNUM = 1;

    pkg_utils.atualizar_status_solicitacao(
        v_solicitacao.familiar_id,
        v_solicitacao.funcionario_id,
        v_solicitacao.data_solicitacao,
        'Em Andamento', 
        v_msg,
        v_sucess
    );

    -- Exibe o resultado
    DBMS_OUTPUT.PUT_LINE('Sucesso: ' || v_sucess);
    DBMS_OUTPUT.PUT_LINE('Mensagem: ' || v_msg);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/

-- (Comandos utilizados: SELECT, FROM, WHERE, JOIN, ORDER BY, BETWEEN)
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


-- (Comandos utilizados: LEFT JOIN, GROUP BY, COUNT)
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

-- (Comandos utilizados: HAVING)
-- Relatório sobre os funcionários que receberam mais solicitações
-- Seleciona somente aqueles que receberam mais de uma solicitação
-- Exibe nome e total de solicitações recebidas pelo funcionário
SELECT pes.nome, COUNT(*) AS total
FROM Solicitacao s
JOIN  Pessoa pes ON pes.id = s.funcionario_id
GROUP BY pes.nome, s.funcionario_id
HAVING COUNT(*) > 1
ORDER BY total DESC;

-- (Comandos utilizados: RECORD, TABLE, %TYPE, CURSOR, OPEN, FETCH, CLOSE, WHILE, MIN, MAX, AVG, EXIT WHEN)
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

-- (Comandos utilizados: Subconsulta com IN)
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

-- (Comandos utilizados: Subconsulta com ANY e operador relacional)
-- Seleciona funcionários não coveiros que recebem menos que algum coveiro
SELECT p.nome, f.data_contratacao, f.funcao, f.salario FROM FUNCIONARIO f
JOIN Pessoa p ON p.id = f.id
WHERE salario < ANY (
    SELECT salario FROM Funcionario WHERE funcao = 'Coveiro'
)
AND Funcao != 'Coveiro';

-- (Comandos utilizados: Subconsulta com ALL e operador relacional)
-- Seleciona jazigos com capacidade maior do que o total de sepultamentos em qualquer jazigo
SELECT * FROM Jazigo
WHERE capacidade > ALL (
    SELECT COUNT(*)
    FROM Sepultamento
    GROUP BY jazigo_id
);

-- (Comandos utilizados: INSERT INTO)
-- Para testar o comando abaixo
INSERT INTO Pessoa(id, nome, tipo) VALUES (TRUNC(DBMS_RANDOM.VALUE(500000, 99999999)), 'Getúlio Vargas', 'Falecido');

-- (Comandos utilizados: LIKE, CASE)
-- Seleciona falecidos cujo sobrenome é Vargas, indica se algum deles é Getúlio Vargas
SELECT nome,
CASE 
    WHEN nome like 'Getúlio%' THEN 'SIM!'
    ELSE 'NÃO!' 
    END AS ele_esta_aqui
FROM Pessoa 
WHERE nome LIKE '%Vargas' AND tipo = 'Falecido';

-- (Comandos utilizados: ALTER TABLE)
-- Adiciona coluna para observações nos sepultamentos
ALTER TABLE Sepultamento ADD observacoes VARCHAR2(500);

-- (Comandos utilizados: UPDATE)
-- Aplica reajuste salarial para os funcionários com base em função e tempo de serviço
-- Aumenta o salário de todo não coveiro com salário menor que o coveiro mais bem pago
UPDATE Funcionario f
SET salario = salario * 
    CASE 
        WHEN MONTHS_BETWEEN(SYSDATE, data_contratacao) > 60 THEN 1.25
        WHEN MONTHS_BETWEEN(SYSDATE, data_contratacao) > 30 THEN 1.15
        ELSE 1.10
    END
WHERE funcao != 'Coveiro'
AND salario < (
    SELECT MAX(salario) 
    FROM Funcionario 
    WHERE funcao = 'Coveiro'
);

-- (Comandos utilizados: DELETE)
-- Remove solicitações canceladas com mais de 5 anos
DELETE FROM Solicitacao
WHERE status_solicitacao = 'Cancelada'
AND data_solicitacao < ADD_MONTHS(SYSDATE, -60);

-- (Comandos utilizados: COUNT, AVG, GROUP BY, HAVING, ORDER BY)
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

-- (Comandos utilizados: UNION)
-- Relatório combinado de falecidos e responsáveis por jazigo
-- A ordenação garante que o responsável pelo jazigo apareça logo antes de todos os falecidos naquele jazigo
-- Data relevante é data de sepultamento para falecido e data de ínicio da responsabilidade para responsável
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
ORDER BY localizacao, tipo DESC;

-- (Comandos utilizados: CREATE VIEW)
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

-- (Comandos utilizados: IS NOT NULL)
-- Seleciona aqueles jazigos na view que tiverem manutencão registrada
SELECT * FROM VW_GESTAO_JAZIGOS
WHERE ULTIMA_MANUTENCAO IS NOT NULL;

-- (Comandos utilizados: CREATE FUNCTION, EXCEPTION)
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
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END calcular_tempo_medio_servico;
/
DECLARE
    v_tempo_medio NUMBER;
BEGIN
    v_tempo_medio := ROUND(calcular_tempo_medio_servico, 3);
    DBMS_OUTPUT.PUT_LINE('Tempo médio: ' || v_tempo_medio || ' dias');
END;
/

-- (Comandos utilizados: CASE, COUNT, LEFT JOIN, GROUP BY, ORDER BY)
-- Relatório da produtividade de funcionários
-- Dá uma nota dependendo da média de valor por solicitação que o funcionário gerou até o momento
SELECT 
    f.id,
    pes.nome,
    COUNT(s.FUNCIONARIO_ID) as solicitacoes_totais,
    COALESCE(SUM(sf.valor), 0) AS valor_total,
    CASE
        WHEN COALESCE(SUM(sf.valor), 0)/GREATEST(COUNT(s.FUNCIONARIO_ID), 1) > 30000 THEN 'S'
        WHEN COALESCE(SUM(sf.valor), 0)/GREATEST(COUNT(s.FUNCIONARIO_ID), 1) > 20000 THEN 'A'
        WHEN COALESCE(SUM(sf.valor), 0)/GREATEST(COUNT(s.FUNCIONARIO_ID), 1) > 10000 THEN 'B'
        WHEN COALESCE(SUM(sf.valor), 0)/GREATEST(COUNT(s.FUNCIONARIO_ID), 1) > 5000 THEN 'C'
        WHEN COALESCE(SUM(sf.valor), 0)/GREATEST(COUNT(s.FUNCIONARIO_ID), 1) > 1000 THEN 'D'
        ELSE 'F'
    END AS produtividade
FROM Funcionario f
JOIN Pessoa pes ON pes.id = f.id
LEFT JOIN Solicitacao s ON s.funcionario_id = f.id
LEFT JOIN ServicoFunerario sf ON sf.id = s.servico_id
GROUP BY f.id, pes.nome
ORDER BY valor_total DESC, solicitacoes_totais DESC;

-- (Comandos utilizados: %ROWTYPE, SELECT INTO, DBMS_OUTPUT, EXCEPTION)
-- Script para exibir os detalhes de um sepultamento aleatório usando %ROWTYPE.
-- O %ROWTYPE cria uma variável do tipo registro que corresponde à estrutura de uma linha da tabela Sepultamento,
-- simplificando a manipulação dos dados recuperados.
DECLARE
    -- Declara uma variável de registro para armazenar uma linha completa da tabela Sepultamento.
    v_sepultamento_rec Sepultamento%ROWTYPE;

    -- Variáveis para armazenar informações adicionais.
    v_nome_falecido Pessoa.nome%TYPE;
    v_local_jazigo VARCHAR2(100);

BEGIN
    -- Seleciona uma linha aleatória da tabela Sepultamento e a armazena na variável de registro.
    SELECT *
    INTO v_sepultamento_rec
    FROM (
        SELECT * FROM Sepultamento ORDER BY DBMS_RANDOM.VALUE
    )
    WHERE ROWNUM = 1;

    -- Usando o falecido_id do registro, busca o nome da pessoa na tabela Pessoa.
    SELECT nome
    INTO v_nome_falecido
    FROM Pessoa
    WHERE id = v_sepultamento_rec.falecido_id;

    -- Usando o jazigo_id do registro, busca os detalhes de localização na tabela Jazigo.
    SELECT 'Quadra: ' || quadra || ', Fila: ' || fila || ', Número: ' || numero
    INTO v_local_jazigo
    FROM Jazigo
    WHERE id = v_sepultamento_rec.jazigo_id;

    -- Exibe os detalhes formatados do sepultamento.
    DBMS_OUTPUT.PUT_LINE('--- Detalhes do Sepultamento ---');
    DBMS_OUTPUT.PUT_LINE('Nome do Falecido: ' || v_nome_falecido);
    DBMS_OUTPUT.PUT_LINE('Data do Sepultamento: ' || TO_CHAR(v_sepultamento_rec.data, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Tipo de Sepultamento: ' || v_sepultamento_rec.tipo);
    DBMS_OUTPUT.PUT_LINE('Localização do Jazigo: ' || v_local_jazigo);

EXCEPTION
    -- Trata o caso de não encontrar nenhum sepultamento na tabela.
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nenhum registro de sepultamento encontrado.');
    -- Trata outros erros possíveis.
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ocorreu um erro: ' || SQLERRM);
END;
/

-- (Comandos utilizados: COUNT, MAX, GROUP, HAVING, ORDER BY)
-- Análise de sepultamentos por localização específica
-- Agrupa sepultamentos por quadra e fila e incluí informação
-- sobre total de sepultamentos na fila e a idade média e máxima dos falecidos na data de sua morte
SELECT 
    j.quadra,
    j.fila,
    COUNT(*) AS total_sepultamentos,
    TRUNC(AVG(idade)) AS idade_media,
    MAX(idade) AS idade_maxima
FROM (
    SELECT 
        s.jazigo_id,
        TRUNC(MONTHS_BETWEEN(f.data_falecimento, p.data_nascimento)/12) AS idade
    FROM Sepultamento s
    JOIN Falecido f ON s.falecido_id = f.id
    JOIN Pessoa p on s.falecido_id = p.id
) sep_idades
JOIN Jazigo j ON sep_idades.jazigo_id = j.id
GROUP BY j.quadra, j.fila
ORDER BY quadra, fila;

-- (Comandos utilizados: LEFT JOIN, GROUP BY)
-- Seleciona jazigos com menos de 50% de ocupação e com sepultamentos mais antigos que 5 anos
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

-- Exemplos de controle de acesso
/*
GRANT SELECT ON vw_gestao_jazigos TO gestor_cemiterio;
REVOKE DELETE ON Sepultamento FROM atendente;
*/