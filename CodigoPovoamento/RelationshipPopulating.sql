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
    v_motivos SYS.ODCIVARCHAR2LIST := ODCIVARCHAR2LIST(
        'Investigação judicial',
        'Construção ou reforma do cemitério',
        'Identificação de restos mortais',
        'Solicitação da família',
        'Necessidade de espaço',
        'Exumação sanitária',
        'Mudança de jazigo'
    );

    CURSOR c_falecidos IS
        SELECT id, data_falecimento  
        FROM Falecido
        WHERE data_falecimento < SYSDATE - 5*365;

    -- Função para gerar data de exumação
    FUNCTION gerar_data_exumacao(v_data_morte IN DATE) RETURN DATE IS
        v_result DATE; 
    BEGIN
        LOOP
            v_result := v_data_morte + TRUNC(DBMS_RANDOM.VALUE(1, 365 * 30)); 
            EXIT WHEN v_result <= SYSDATE; 
        END LOOP;
        RETURN v_result;
    END;

    v_cursor_idx INT := 0;

    v_data_exumacao DATE;
    v_funcionario_id INT;
    v_jazigo_id INT;
    v_motivo VARCHAR2(500);
BEGIN
    FOR f IN c_falecidos LOOP
        v_cursor_idx := v_cursor_idx + 1;
        EXIT WHEN v_cursor_idx = 11;

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

        INSERT INTO Exumacao(falecido_id, jazigo_id, funcionario_id, data, motivo)
        VALUES (f.id, v_jazigo_id, v_funcionario_id, v_data_exumacao, v_motivo);
    END LOOP;
END;
/

-- Popular Parentesco
DECLARE
    v_parentesco_M SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Pai', 'Filho', 'Irmão', 'Marido', 'Avô', 'Neto', 'Tio', 'Outro'
    );

    v_parentesco_F SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Mãe', 'Filha', 'Irmã', 'Esposa', 'Avó', 'Neta', 'Tia', 'Outro'
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

        -- Escolhe tipo de parentesco conforme sexo
        IF fam.sexo = 'Masculino' THEN
            v_tipo := v_parentesco_M(TRUNC(DBMS_RANDOM.VALUE(1, v_parentesco_M.COUNT + 1)));
        ELSE
            v_tipo := v_parentesco_F(TRUNC(DBMS_RANDOM.VALUE(1, v_parentesco_F.COUNT + 1)));
        END IF;

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

