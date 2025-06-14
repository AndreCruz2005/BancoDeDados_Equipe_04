-- Telefone e Endereço
DECLARE
    CURSOR c_pessoas_vivas IS
        SELECT id FROM Pessoa 
        WHERE tipo != 'Falecido';

    v_numero VARCHAR2(13);
    v_cep VARCHAR2(8);
BEGIN

    FOR p IN c_pessoas_vivas LOOP

        -- Popular telefone
        SELECT numero
        INTO v_numero 
        FROM (
            SELECT numero FROM Telefone
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        INSERT INTO PessoaTelefone(numero, pessoa_id) 
        VALUES (v_numero, p.id);
        
        -- Popular Endereço
        SELECT cep
        INTO v_cep 
        FROM (
            SELECT cep FROM Endereco
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        INSERT INTO PessoaEndereco(cep, pessoa_id) 
        VALUES (v_cep, p.id);
    END LOOP;   
END;
/

-- Exumação --
DECLARE
    v_motivos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Investigação judicial',
        'Construção ou reforma do cemitério',
        'Identificação de restos mortais',
        'Solicitação da família',
        'Necessidade de espaço',
        'Exumação sanitária',
        'Mudança de jazigo'
    );

    v_cursor_idx INT := 0;

    v_data_exumacao DATE;
    v_funcionario_id INT;
    v_jazigo_id INT;
    v_motivo VARCHAR2(500);

    CURSOR c_falecidos IS
        SELECT id, data_falecimento
        FROM Falecido
        WHERE data_falecimento < SYSDATE - 5*365;

    -- Função para gerar data de exumação
    FUNCTION gerar_data_exumacao(v_data_morte IN DATE) RETURN DATE IS
        v_result DATE; 
    BEGIN
        v_result := SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 365 * 30)); 
        RETURN GREATEST(v_result, v_data_morte+7);
    END;
BEGIN
    FOR f IN c_falecidos LOOP
        v_cursor_idx := v_cursor_idx + 1;
        EXIT WHEN v_cursor_idx > 10;

        v_data_exumacao := gerar_data_exumacao(f.data_falecimento);
        v_motivo := v_motivos(TRUNC(DBMS_RANDOM.VALUE(1, v_motivos.COUNT + 1)));

        SELECT id 
        INTO v_funcionario_id 
        FROM (
            SELECT id FROM Funcionario 
            ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1; 

        SELECT id 
        INTO v_jazigo_id 
        FROM (
            SELECT id FROM Jazigo 
            ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1; 

        BEGIN
            INSERT INTO Exumacao(falecido_id, jazigo_id, funcionario_id, data, motivo)
            VALUES (f.id, v_jazigo_id, v_funcionario_id, v_data_exumacao, v_motivo);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
        END;
    END LOOP;
END;
/

-- Popular Parentesco
DECLARE
    v_parentesco SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Primeiro grau', 'Segundo grau', 'Terceiro grau', 'Outro'
    );

    v_tipo VARCHAR2(50);
    v_falecido_id INT;

    CURSOR c_familiares IS
        SELECT id, sexo FROM Pessoa
        WHERE id IN (SELECT id FROM Familiar);
BEGIN
    FOR fam IN c_familiares LOOP
        -- Seleciona um falecido aleatório para cada familiar
        SELECT id INTO v_falecido_id
        FROM (
            SELECT id FROM Falecido
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        -- Escolhe tipo de parentesco
        v_tipo := v_parentesco(TRUNC(DBMS_RANDOM.VALUE(1, v_parentesco.COUNT + 1)));

        -- Inserção no relacionamento
        INSERT INTO Parentesco (familiar_id, falecido_id, tipo)
        VALUES (fam.id, v_falecido_id, v_tipo);
    END LOOP;
END;
/

-- Popular gerencia
DECLARE
    CURSOR c_gerentes IS
        SELECT id FROM (
            SELECT id FROM Funcionario
            ORDER BY salario DESC
        ) WHERE ROWNUM < 6;

    v_gerenciado_id INT;
BEGIN
    FOR g IN c_gerentes LOOP
        FOR i IN 1..TRUNC(DBMS_RANDOM.VALUE(1, 15)) LOOP
            SELECT id INTO v_gerenciado_id
            FROM (
                SELECT id FROM Funcionario
                WHERE id != g.id
                ORDER BY DBMS_RANDOM.VALUE
            )
            WHERE ROWNUM = 1;

            BEGIN
                INSERT INTO Gerencia(gerente_id, gerenciado_id)
                VALUES (g.id, v_gerenciado_id);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    NULL; -- Ignora duplicatas
            END;
        END LOOP;
    END LOOP;
END;
/

-- Popular Solicitação e Serviço Funerário
DECLARE
    -- Solicitação
    v_data_solicitacao DATE;
    v_familiar_id INT;
    v_funcionario_id INT;
    v_status_solicitacao VARCHAR2(18);
    v_status_possiveis SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Pagamento Pendente', 'Em Andamento', 'Concluida', 'Cancelada'
    );

    -- Serviço
    v_servico_id INT;
    v_valor NUMBER(8, 2);
    v_data DATE;
    v_tipo VARCHAR2(50);
    v_tipos_servico SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Translado de Corpo', 'Velório', 'Cremação', 'Tanatopraxia',
        'Ornamentação de Urna', 'Locação de Sala de Velório',
        'Cortejo Fúnebre', 'Preparação de Corpo', 'Assessoria Documental',
        'Transporte de Familiares','Locação de Jazigo','Serviço Musical',
        'Homenagem Floral', 'Cerimonial', 'Urna Funerária'
    );
BEGIN
    FOR i IN 1..25 LOOP
        v_servico_id := NULL;
        v_data_solicitacao := SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 10*365));

        SELECT id
        INTO v_familiar_id
        FROM (
            SELECT id FROM Pessoa 
            WHERE tipo = 'Familiar' AND v_data_solicitacao - data_nascimento >= 18  
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        SELECT id
        INTO v_funcionario_id
        FROM (
            SELECT id FROM Funcionario 
            WHERE v_data_solicitacao > data_contratacao 
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        v_status_solicitacao := v_status_possiveis(TRUNC(DBMS_RANDOM.VALUE(1, v_status_possiveis.COUNT + 1)));

        -- Cria serviço associado à solicitação se o status for apropriado
        IF v_status_solicitacao = 'Em Andamento' OR v_status_solicitacao = 'Concluida' THEN
            v_servico_id := global_id_seq.NEXTVAL;
            v_data := v_data_solicitacao + TRUNC(DBMS_RANDOM.VALUE(1, 15));
            v_valor := ROUND(DBMS_RANDOM.VALUE(100, 50000), 2);
            v_tipo := v_tipos_servico(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos_servico.COUNT + 1)));

            INSERT INTO ServicoFunerario(id, tipo, valor, data)
            VALUES (v_servico_id, v_tipo, v_valor, v_data);
        END IF;
        
        INSERT INTO Solicitacao(data_solicitacao, servico_id, familiar_id, funcionario_id, status_solicitacao)
        VALUES (v_data_solicitacao, v_servico_id, v_familiar_id, v_funcionario_id, v_status_solicitacao);
    END LOOP;
END;
/

-- Popular ManutencaoJazigo e OcorrenciaManutencao
DECLARE
    v_jazigo_id INT;
    v_funcionario_id INT;
    v_data_inicio DATE;
    v_data_fim DATE;
    v_motivo VARCHAR2(500);
    v_motivos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Limpeza geral',
        'Reparo estrutural',
        'Pintura',
        'Troca de placas',
        'Impermeabilização',
        'Reforma de cobertura',
        'Manutenção preventiva',
        'Remoção de infiltração'
    );
    v_manutencao_id INT;
BEGIN
    -- Insere 20 manutenções
    FOR i IN 1..20 LOOP
        v_data_inicio := SYSDATE - TRUNC(DBMS_RANDOM.VALUE(30, 365*10));
        v_data_fim := v_data_inicio + TRUNC(DBMS_RANDOM.VALUE(1, 30));
        v_motivo := v_motivos(TRUNC(DBMS_RANDOM.VALUE(1, v_motivos.COUNT + 1)));

        -- Seleciona jazigo e funcionário aleatórios
        SELECT id INTO v_jazigo_id FROM (
            SELECT id FROM Jazigo ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1;

        SELECT id INTO v_funcionario_id FROM (
            SELECT id FROM Funcionario
            WHERE v_data_inicio > data_contratacao
            ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1;

        INSERT INTO ManutencaoJazigo(jazigo_id, funcionario_id, data_inicio, data_fim, motivo)
        VALUES (v_jazigo_id, v_funcionario_id, v_data_inicio, v_data_fim, v_motivo)
        RETURNING id INTO v_manutencao_id;

        -- Para cada manutenção, insere de 1 a 4 ocorrências
        FOR j IN 1..TRUNC(DBMS_RANDOM.VALUE(1, 5)) LOOP
            BEGIN
                INSERT INTO OcorrenciaManutencao(manutencao_id, data_ocorrencia, descricao)
                VALUES (
                    v_manutencao_id,
                    v_data_inicio + TRUNC(DBMS_RANDOM.VALUE(0, v_data_fim - v_data_inicio + 1)),
                    'Ocorrência: ' || v_motivo || ' - Detalhe ' || j
                );
            EXCEPTION 
                WHEN DUP_VAL_ON_INDEX THEN
                    NULL;
            END;
        END LOOP;
    END LOOP;
END;
/

-- Popular Utiliza
DECLARE
    CURSOR c_ocorrencias IS
        SELECT manutencao_id, data_ocorrencia FROM OcorrenciaManutencao;

    v_material_id INT;
BEGIN
    FOR o IN c_ocorrencias LOOP
        -- Para cada ocorrência, insere de 1 a 3 materiais utilizados
        FOR i IN 1..TRUNC(DBMS_RANDOM.VALUE(1, 4)) LOOP
            SELECT id INTO v_material_id
            FROM (
                SELECT id FROM Material
                ORDER BY DBMS_RANDOM.VALUE
            ) WHERE ROWNUM = 1;

            BEGIN
                INSERT INTO Utiliza(material_id, manutencao_id, data_ocorrencia)
                VALUES (v_material_id, o.manutencao_id, o.data_ocorrencia);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    NULL; -- Ignora duplicatas
            END;
        END LOOP;
    END LOOP;
END;
/

-- Popular sepultamento

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

DECLARE
    v_jazigo_id     INT;
    v_data          DATE;
    v_qt_exumacoes  INT;
    v_sucesso       BOOLEAN;

    CURSOR c_falecidos IS
        SELECT id, data_falecimento FROM Falecido;
BEGIN
    FOR f IN c_falecidos LOOP
        -- Gera a data do sepultamento, se houve exumações pode ser um maior tempo após a morte
        SELECT COUNT(*) INTO v_qt_exumacoes
        FROM Exumacao
        WHERE falecido_id = f.id;

        IF v_qt_exumacoes > 0 THEN 
            v_data := LEAST(f.data_falecimento + TRUNC(DBMS_RANDOM.VALUE(1, 365*150)), SYSDATE);
        ELSE 
            v_data := LEAST(f.data_falecimento + TRUNC(DBMS_RANDOM.VALUE(1, 365)), SYSDATE);
        END IF;

        -- Tenta encontrar um jazigo válido
        v_sucesso := FALSE;
        WHILE NOT v_sucesso LOOP
            -- Escolhe um jazigo aleatório
            SELECT id INTO v_jazigo_id
            FROM (
                SELECT id FROM Jazigo
                ORDER BY DBMS_RANDOM.VALUE
            ) WHERE ROWNUM = 1;

            -- Tenta inserir
            BEGIN
                INSERT INTO Sepultamento(falecido_id, jazigo_id, data)
                VALUES (f.id, v_jazigo_id, v_data);
                v_sucesso := TRUE;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Erro por capacidade: tenta outro jazigo
                    NULL;
            END;
        END LOOP;
    END LOOP;
END;
/

-- Gerar responsabilidade por jazigos
DECLARE
    v_jazigo_id INT;
    v_pagamento NUMBER(8, 2);
    v_aluguel NUMBER(8, 2);
    v_data_inicio DATE;
    v_data_fim DATE;
    v_responsavel_data_nascimento DATE;

    CURSOR c_familiar_falecido IS
        SELECT familiar_id, falecido_id
        FROM Parentesco;
BEGIN
    FOR ff IN c_familiar_falecido LOOP
        SELECT jazigo_id
        INTO v_jazigo_id
        FROM Sepultamento
        WHERE falecido_id = ff.falecido_id AND ROWNUM = 1;

        v_pagamento := ROUND(DBMS_RANDOM.VALUE(0, 50000), 2);
        v_aluguel := ROUND(DBMS_RANDOM.VALUE(0, 2000), 2);

        SELECT data_nascimento 
        INTO v_responsavel_data_nascimento
        FROM Pessoa
        WHERE id = ff.familiar_id;

        v_data_inicio := LEAST(SYSDATE, v_responsavel_data_nascimento + TRUNC(DBMS_RANDOM.VALUE(19*365, 70*365)));

        IF v_data_inicio > SYSDATE - 4*365 THEN
            v_data_fim := NULL;
        ELSE 
            v_data_fim := LEAST(SYSDATE, v_data_inicio + TRUNC(DBMS_RANDOM.VALUE(1*365, 20*365)));
        END IF;

        INSERT INTO ResponsabilidadeJazigo 
        (jazigo_id, responsavel_id, pagamento, aluguel, data_inicio, data_fim)
        VALUES (v_jazigo_id, ff.familiar_id, v_pagamento, v_aluguel, v_data_inicio, v_data_fim);
    END LOOP;
END;
/