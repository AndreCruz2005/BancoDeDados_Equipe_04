-- Telefone e Endereço
DECLARE
    CURSOR c_pessoas_vivas IS
        SELECT id FROM Pessoa 
        WHERE tipo != 'Falecido';

    v_numero VARCHAR2(13);
    v_cep VARCHAR2(8);

    v_numero_endereco INT;
    v_complemento VARCHAR2(50); 
BEGIN

    FOR p IN c_pessoas_vivas LOOP

        -- Popular telefone aleatório
        SELECT numero
        INTO v_numero 
        FROM (
            SELECT numero FROM Telefone
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        INSERT INTO PessoaTelefone(numero, pessoa_id) 
        VALUES (v_numero, p.id);
        
        -- Popular endereço aleatório
        SELECT cep
        INTO v_cep 
        FROM (
            SELECT cep FROM Endereco
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        -- Gerar número do endereço entre 1 e 1000
        v_numero_endereco := TRUNC(DBMS_RANDOM.VALUE(1, 1001));

        -- Gerar complemento opcional
        IF DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
            v_complemento := '';
        ELSE
            v_complemento := 'Apt ' || TRUNC(DBMS_RANDOM.VALUE(1, 1001));
        END IF;

        INSERT INTO PessoaEndereco(cep, pessoa_id, numero, complemento) 
        VALUES (v_cep, p.id, v_numero_endereco, v_complemento);
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

    count_limit INT := 0;

    v_falecido Falecido%ROWTYPE;
    v_funcionario Funcionario%ROWTYPE; 
    v_jazigo_id INT;
    v_data_exumacao DATE;
    v_motivo VARCHAR2(500);

BEGIN
    WHILE count_limit < pkg_global_vars.QT_EXUMACOES LOOP

        SELECT * INTO v_falecido FROM (SELECT * FROM Falecido WHERE id NOT IN (SELECT falecido_id FROM Exumacao) ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        SELECT * INTO v_funcionario FROM (SELECT * FROM Funcionario ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        SELECT id into v_jazigo_id FROM (SELECT id from Jazigo ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;

        -- Escolhe o mais recente entre uma data aletória, 7 dias após o falecimento e a contratação do funcionário selecionado
        v_data_exumacao := GREATEST(
            v_falecido.data_falecimento+7, 
            SYSDATE-DBMS_RANDOM.VALUE(0, 30*365.25),
            v_funcionario.data_contratacao
        );

        v_motivo := v_motivos(TRUNC(DBMS_RANDOM.VALUE(1, v_motivos.COUNT + 1)));

        BEGIN
            INSERT INTO Exumacao(falecido_id, jazigo_id, funcionario_id, data, motivo)
            VALUES (v_falecido.id, v_jazigo_id, v_funcionario.id, v_data_exumacao, v_motivo);
            count_limit := count_limit + 1;
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
        SELECT id FROM Pessoa
        WHERE Tipo = 'Familiar';
BEGIN
    FOR fam IN c_familiares LOOP
            FOR i in 1..TRUNC(DBMS_RANDOM.VALUE(1, 5)) LOOP
                -- Seleciona um falecido aleatório para o familiar
                SELECT id INTO v_falecido_id
                FROM (
                    SELECT id FROM Falecido
                    ORDER BY DBMS_RANDOM.VALUE
                )
                WHERE ROWNUM = 1;

                -- Escolhe tipo de parentesco
                v_tipo := v_parentesco(TRUNC(DBMS_RANDOM.VALUE(1, v_parentesco.COUNT + 1)));

                -- Inserção no relacionamento
                BEGIN
                    INSERT INTO Parentesco (familiar_id, falecido_id, tipo)
                    VALUES (fam.id, v_falecido_id, v_tipo);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN NULL;
                END;
            END LOOP;
    END LOOP;
END;
/

-- Popular gerencia
DECLARE
    CURSOR c_gerentes IS
        SELECT id FROM (
            SELECT id FROM Funcionario
            ORDER BY salario DESC
        ) WHERE ROWNUM < pkg_global_vars.QT_GERENTES;

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
    v_familiar Pessoa%ROWTYPE;
    v_funcionario Funcionario%ROWTYPE;
    v_data_solicitacao DATE;
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
    FOR i IN 1..pkg_global_vars.QT_SERVICOS LOOP
        v_servico_id := NULL;

        SELECT * INTO v_familiar
        FROM (SELECT * FROM Pessoa WHERE Tipo = 'Familiar' ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;

        SELECT * INTO v_funcionario
        FROM ( SELECT * FROM Funcionario ORDER BY DBMS_RANDOM.VALUE)
        WHERE ROWNUM = 1;

        v_data_solicitacao := GREATEST(
            v_funcionario.data_contratacao, 
            v_familiar.data_nascimento + 18*365.25, 
            SYSDATE-DBMS_RANDOM.VALUE(1*365.25, 15*365.25)
        );

        v_status_solicitacao := v_status_possiveis(TRUNC(DBMS_RANDOM.VALUE(1, v_status_possiveis.COUNT + 1)));

        -- Cria serviço associado à solicitação se o status for apropriado
        IF v_status_solicitacao = 'Em Andamento' OR v_status_solicitacao = 'Concluida' THEN
            v_servico_id := global_id_seq.NEXTVAL;
            pkg_random_data.GERAR_DATA_ALEATORIA(v_data_solicitacao, 1, 15, v_data);
            v_valor := ROUND(DBMS_RANDOM.VALUE(100, 50000), 2);
            v_tipo := v_tipos_servico(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos_servico.COUNT + 1)));

            INSERT INTO ServicoFunerario(id, tipo, valor, data)
            VALUES (v_servico_id, v_tipo, v_valor, v_data);
        END IF;
        
        INSERT INTO Solicitacao(data_solicitacao, servico_id, familiar_id, funcionario_id, status_solicitacao)
        VALUES (v_data_solicitacao, v_servico_id, v_familiar.id, v_funcionario.id, v_status_solicitacao);
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
    -- Insere manutenções
    FOR i IN 1..pkg_global_vars.QT_MANUTENCOES LOOP
        pkg_random_data.GERAR_DATA_ALEATORIA(SYSDATE, -30, -10*365.25, v_data_inicio);
        pkg_random_data.GERAR_DATA_ALEATORIA(v_data_inicio, 1, 30, v_data_fim);
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
    v_tipo VARCHAR2(20);

    v_tipos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Definitivo', 'Temporário');

    CURSOR c_falecidos IS
        SELECT id, data_falecimento FROM Falecido;
BEGIN
    FOR f IN c_falecidos LOOP
        -- Gera a data do sepultamento, se houve exumações pode ser um maior tempo após a morte
        SELECT COUNT(*) INTO v_qt_exumacoes
        FROM Exumacao
        WHERE falecido_id = f.id;

        CASE v_qt_exumacoes WHEN 0 THEN
            pkg_random_data.GERAR_DATA_ALEATORIA(f.data_falecimento, 1, LEAST(365*50, SYSDATE-f.data_falecimento), v_data);
        ELSE 
            pkg_random_data.GERAR_DATA_ALEATORIA(f.data_falecimento, 1, LEAST(365, SYSDATE-f.data_falecimento), v_data);
        END CASE;

        IF SYSDATE - v_data < 365.25 THEN
            v_tipo := v_tipos(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos.COUNT + 1)));
        ELSE
            v_tipo := 'Definitivo';
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
        
            BEGIN
                INSERT INTO Sepultamento(falecido_id, jazigo_id, data, tipo)
                VALUES (f.id, v_jazigo_id, v_data, v_tipo);
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
    v_pagamento NUMBER(8, 2);
    v_aluguel NUMBER(8, 2);
    v_data_inicio DATE;
    v_data_fim DATE;

    v_exists INT;

    CURSOR c_jazigos_ocupados IS
        SELECT sep.jazigo_id, sep.falecido_id, fam.id AS familiar_id, fam.data_nascimento AS fam_nascimento
        FROM Sepultamento sep
        JOIN Parentesco par ON par.falecido_id = sep.falecido_id
        JOIN Pessoa fam ON fam.id = par.familiar_id;

BEGIN
    FOR j IN c_jazigos_ocupados LOOP
        -- Evita duplicar responsabilidade se já existir
        SELECT COUNT(*) INTO v_exists 
        FROM ResponsabilidadeJazigo 
        WHERE jazigo_id = j.jazigo_id;
        
        IF v_exists > 0 THEN
            CONTINUE;
        END IF;

        v_pagamento := ROUND(DBMS_RANDOM.VALUE(500, 100000), 2);
        v_aluguel := ROUND(DBMS_RANDOM.VALUE(50, 1000), 2);

        -- Gera data de início com base na idade do familiar
        pkg_random_data.GERAR_DATA_ALEATORIA(j.fam_nascimento, 25*365, LEAST(80*365, SYSDATE-j.fam_nascimento), v_data_inicio);

        IF DBMS_RANDOM.VALUE(0, 1) < 0.3 THEN
            v_data_fim := NULL;
        ELSE
            pkg_random_data.GERAR_DATA_ALEATORIA(v_data_inicio, 1*365, 20*365, v_data_fim);
        END IF;

        INSERT INTO ResponsabilidadeJazigo (jazigo_id, responsavel_id, pagamento, aluguel, data_inicio, data_fim)
        VALUES (j.jazigo_id, j.familiar_id, v_pagamento, v_aluguel, v_data_inicio, v_data_fim);
    END LOOP;
END;
/
