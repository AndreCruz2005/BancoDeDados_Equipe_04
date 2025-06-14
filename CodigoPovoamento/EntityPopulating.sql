CREATE SEQUENCE global_id_seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

---- POPULAR PESSOAS BEGIN ----

DECLARE
    v_nomes_masculinos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'João', 'Pedro', 'Lucas', 'Mateus', 'Gabriel',
        'Felipe', 'Guilherme', 'Bruno', 'Thiago', 'Leonardo',
        'Carlos', 'José', 'Antonio', 'Rafael', 'Ricardo', 'Getúlio'
    );

    v_nomes_femininos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Maria', 'Ana', 'Juliana', 'Camila', 'Fernanda',
        'Larissa', 'Patrícia', 'Aline', 'Beatriz', 'Mariana',
        'Luana', 'Gabriela', 'Carla', 'Letícia', 'Vanessa'
    );

    v_sobrenomes SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Silva', 'Souza', 'Costa', 'Santos', 'Oliveira',
        'Pereira', 'Rodrigues', 'Almeida', 'Nascimento', 'Lima',
        'Gomes', 'Martins', 'Araújo', 'Barbosa', 'Ribeiro',
        'Carvalho', 'Ferreira', 'Rocha', 'Dias', 'Melo',
        'Moreira', 'Teixeira', 'Campos', 'Cardoso', 'Freitas',
        'Monteiro', 'Lopes', 'Alves', 'Moura', 'Cavalcante',
        'Ramos', 'Pinto', 'Machado', 'Gonçalves', 'Nogueira',
        'Marques', 'Batista', 'Medeiros', 'Cruz', 'Farias',
        'Dias', 'Andrade', 'Rezende', 'Castro', 'Vargas',
        'Siqueira', 'Barros', 'Azevedo', 'Tavares', 'Peixoto'
    );

    v_sexos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Masculino', 'Feminino');
    v_tipos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Familiar', 'Funcionario', 'Falecido');

    v_nome_completo VARCHAR2(100);
    v_cpf  VARCHAR2(11);
    v_data_nascimento DATE;
    v_sexo VARCHAR2(9);
    v_tipo VARCHAR2(11);

    FUNCTION gerar_cpf RETURN VARCHAR2 IS
        v_result VARCHAR2(11);
        v_exists INT;
    BEGIN
        LOOP
            v_result := '';
            FOR i IN 1..11 LOOP
                v_result := v_result || TRUNC(DBMS_RANDOM.VALUE(0, 10));
            END LOOP;
                
            SELECT COUNT(*)
            INTO v_exists
            FROM Pessoa
            WHERE cpf = v_result;

            EXIT WHEN v_exists = 0;
        END LOOP;

        RETURN v_result;
    END;

BEGIN
    FOR i IN 1..200 LOOP
        -- Gera sexo e tipo
        v_sexo := v_sexos(TRUNC(DBMS_RANDOM.VALUE(1, v_sexos.COUNT + 1)));
        v_tipo := v_tipos(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos.COUNT + 1)));

        -- Gera nome completo aleatório
        CASE v_sexo
            WHEN 'Masculino' THEN
                v_nome_completo := v_nomes_masculinos(TRUNC(DBMS_RANDOM.VALUE(1, v_nomes_masculinos.COUNT + 1))) || ' ' ||
                v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, v_sobrenomes.COUNT + 1)));

            WHEN 'Feminino' THEN
                v_nome_completo := v_nomes_femininos(TRUNC(DBMS_RANDOM.VALUE(1, v_nomes_femininos.COUNT + 1))) || ' ' ||
                v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, v_sobrenomes.COUNT + 1)));
        END CASE;

        IF v_tipo = 'Falecido' THEN
            v_cpf := NULL;
        ELSE
            v_cpf := gerar_cpf;
        END IF;

        IF v_tipo = 'Falecido' THEN
            --1800-2025--
            v_data_nascimento := TO_DATE('01/01/1800', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*225));
        ELSIF v_tipo = 'Funcionario' THEN
            --1950-2007--
            v_data_nascimento := TO_DATE('01/01/1950', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*57));
        ELSE
            --1910-2007--
            v_data_nascimento := TO_DATE('01/01/1910', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*97));
        END IF;
       
        INSERT INTO Pessoa(id, nome, cpf, data_nascimento, sexo, tipo)
        VALUES (global_id_seq.NEXTVAL, v_nome_completo, v_cpf, v_data_nascimento, v_sexo, v_tipo);

    END LOOP;
END;
/

-- POPULAR FUNCIONARIOS BEGIN --

DECLARE
    v_funcoes SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Coveiro','Recepcionista', 'Agente Funerário', 'Jardineiro','Eletricista',
    'Encanador', 'Pedreiro', 'Zelador', 'Contador', 'Gerente de Vendas de Jazigos', 'Arquivista', 
    'Segurança', 'Motorista', 'Conselheiro de Luto');

    v_salario NUMBER(8, 2);
    v_funcao VARCHAR2(50);
    v_data_contratacao DATE;

    CURSOR c_funcionarios IS
        SELECT id, data_nascimento FROM Pessoa
        WHERE tipo = 'Funcionario'
        AND id NOT IN (SELECT id FROM Funcionario);
BEGIN

    FOR f in c_funcionarios LOOP
        v_salario := ROUND(DBMS_RANDOM.VALUE(1600, 20000), 2);    
        v_funcao := v_funcoes(TRUNC(DBMS_RANDOM.VALUE(1, v_funcoes.COUNT + 1)));

        IF f.data_nascimento >= TO_DATE('01/01/2000', 'DD/MM/YYYY') THEN
            v_data_contratacao := TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 365));
        ELSIF f.data_nascimento >= TO_DATE('01/01/1990', 'DD/MM/YYYY') THEN
            v_data_contratacao := TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 365*7));
        ELSE
            v_data_contratacao := TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 365*14));
        END IF;

        INSERT INTO Funcionario(id, data_contratacao, funcao, salario)
        VALUES (f.id, v_data_contratacao, v_funcao, v_salario);
    END LOOP;
END;
/
-- POPULAR FUNCIONARIOS END --

-- POPULAR FALECIDOS BEGIN --

DECLARE
    v_causas_morte SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Infarto do miocárdio','Acidente vascular cerebral','Câncer terminal',
        'Insuficiência respiratória','Doença pulmonar obstrutiva crônica','Complicações pós-cirúrgicas',
        'Falência múltipla dos órgãos','Acidente de trânsito','Homicídio','Suicídio','Afogamento',
        'Queda acidental','Choque séptico','Doença hepática crônica','Infecção generalizada','Desnutrição severa',
        'Queimaduras graves','Intoxicação por substâncias','Ataque de animal','Desabamento','Hipotermia','Inalação de fumaça',
        'Parada cardíaca súbita','Reação alérgica grave','Eletrocussão','Erro médico'
    );

    v_causa_obito VARCHAR2(50);
    v_numero_documento_obito VARCHAR2(32);
    v_data_falecimento DATE;

    CURSOR c_falecidos IS
        SELECT id, data_nascimento FROM Pessoa
        WHERE tipo = 'Falecido'
          AND id NOT IN (SELECT id FROM Falecido);

    FUNCTION gerar_doc_obito RETURN VARCHAR2 IS
        v_result VARCHAR2(32);
        v_exists INT;
    BEGIN
        LOOP
            v_result := '';
            FOR i IN 1..32 LOOP
                v_result := v_result || TRUNC(DBMS_RANDOM.VALUE(0, 10));
            END LOOP;

            SELECT COUNT(*)
            INTO v_exists
            FROM Falecido
            WHERE numero_documento_obito = v_result;

            EXIT WHEN v_exists = 0;            
        END LOOP;
        RETURN v_result;
    END;

    FUNCTION gerar_falecimento(p_data_nascimento IN DATE) RETURN DATE IS
        v_random_age INT;
        v_death_date DATE;
    BEGIN
        
        v_random_age := TRUNC(DBMS_RANDOM.VALUE(0, 111));
        v_death_date := p_data_nascimento + v_random_age * 365;
        RETURN LEAST(SYSDATE, v_death_date);
    END;
BEGIN
    FOR f IN c_falecidos LOOP
        v_causa_obito := v_causas_morte(TRUNC(DBMS_RANDOM.VALUE(1, v_causas_morte.COUNT + 1)));
        v_numero_documento_obito := gerar_doc_obito;
        v_data_falecimento := gerar_falecimento(f.data_nascimento);
     
        INSERT INTO Falecido (id, data_falecimento, causa_obito, numero_documento_obito)
        VALUES (f.id, v_data_falecimento, v_causa_obito, v_numero_documento_obito);
    END LOOP;
END;
/
-- POPULAR FALECIDOS END --

-- POPULAR FAMILIARES BEGIN --

DECLARE
    CURSOR c_familiares IS
        SELECT id FROM Pessoa
        WHERE tipo = 'Familiar'
        AND id NOT IN (SELECT id FROM Familiar); 
BEGIN
    FOR f in c_familiares LOOP
        INSERT INTO Familiar(id)
        VALUES (f.id);
    END LOOP;
END;
/
-- POPULAR FAMILIARES END --

---- POPULAR PESSOAS END ----

---- POPULAR ENDEREÇOS BEGIN ----

DECLARE
    v_estados SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
        'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
        'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
    );

    v_cidades SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Rio Branco',     
        'Maceió',        
        'Macapá',        
        'Manaus',        
        'Salvador',       
        'Fortaleza',      
        'Brasília',      
        'Vitória',     
        'Goiânia',      
        'São Luís',       
        'Cuiabá',        
        'Campo Grande',  
        'Belo Horizonte',
        'Belém',         
        'João Pessoa',    
        'Curitiba',      
        'Recife',       
        'Teresina',       
        'Rio de Janeiro', 
        'Natal',         
        'Porto Alegre',   
        'Porto Velho',    
        'Boa Vista',      
        'Florianópolis',  
        'São Paulo',      
        'Aracaju',        
        'Palmas'          
    );

    v_bairros SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Vila da Paz Eterna',
        'Jardim dos Lamentos',
        'Vale do Silêncio',
        'Colina do Repouso',
        'Bosque da Saudade',
        'Morada Final',
        'Parque das Almas',
        'Vila Sepulcral',
        'Bairro Memorial',
        'Horizonte do Crepúsculo'
    );

    v_ruas SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Rua do Descanso',
        'Avenida das Almas',
        'Travessa do Luto',
        'Rua do Adeus',
        'Alameda dos Finados',
        'Rua da Última Jornada',
        'Travessa do Silêncio Eterno',
        'Rua do Jazigo',
        'Avenida da Saudade',
        'Rua do Cemitério'
    );

    v_cep VARCHAR2(8);
    v_estado CHAR(2);
    v_cidade VARCHAR2(50);
    v_bairro VARCHAR2(50);
    v_rua VARCHAR2(100);

    -- INDEXES
    v_estado_idx INT;
    v_bairro_idx INT;

    FUNCTION gerar_cep RETURN VARCHAR2 IS
        v_result VARCHAR2(8);
        v_exists INT;
    BEGIN
        LOOP
            v_result := '';    
            FOR i IN 1..8 LOOP
                v_result := v_result || TRUNC(DBMS_RANDOM.VALUE(0, 10));
            END LOOP;

            SELECT COUNT(*)
            INTO v_exists
            FROM Endereco
            WHERE cep = v_result;

            EXIT WHEN v_exists = 0;
        END LOOP;

        RETURN v_result;
    END;

BEGIN
    FOR i IN 1..50 LOOP
        v_estado_idx := TRUNC(DBMS_RANDOM.VALUE(1, 28));
        v_bairro_idx := TRUNC(DBMS_RANDOM.VALUE(1, 11));

        v_cep := gerar_cep;
        v_estado := v_estados(v_estado_idx);
        v_cidade := v_cidades(v_estado_idx);
        v_bairro := v_bairros(v_bairro_idx);
        v_rua := v_ruas(v_bairro_idx);

        INSERT INTO Endereco(cep, estado, cidade, bairro, rua) 
        VALUES (v_cep, v_estado, v_cidade, v_bairro, v_rua);
    END LOOP;
END;
/
---- POPULAR ENDEREÇOS END ----

---- POPULAR TELEFONES BEGIN ----

DECLARE
    v_numero VARCHAR2(13);

    FUNCTION gerar_telefone RETURN VARCHAR2 IS
        v_result VARCHAR2(13) := '55';
        v_exists INT;
    BEGIN
        LOOP    
            FOR i IN 1..11 LOOP
                v_result := v_result || TRUNC(DBMS_RANDOM.VALUE(0, 10));
            END LOOP;

            SELECT COUNT(*)
            INTO v_exists
            FROM Telefone
            WHERE numero = v_result;

            EXIT WHEN v_exists = 0;
        END LOOP;

        RETURN v_result;
    END;

BEGIN
    FOR i IN 1..70 LOOP
        v_numero := gerar_telefone;
        INSERT INTO Telefone(numero) VALUES (v_numero);
    END LOOP;
END;
/
---- POPULAR TELEFONES END ----

---- POPULAR JAZIGOS BEGIN ----

DECLARE
    v_tipos      SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Simples','Duplo','Familiar','Gaveta');
    v_quadra     INT;
    v_fila       INT;
    v_numero     INT;
    v_capacidade INT;
    v_tipo       VARCHAR2(20);
BEGIN
  FOR q IN 1..4 LOOP
    v_tipo := v_tipos(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos.COUNT + 1)));
    v_quadra := q;

    FOR f IN 1..5 LOOP
      v_fila := f;

      FOR n IN 1..10 LOOP
        v_numero := n;

        CASE v_tipo
          WHEN 'Duplo' THEN
            v_capacidade := 2;
          WHEN 'Familiar' THEN
            v_capacidade := TRUNC(DBMS_RANDOM.VALUE(3, 11));
          ELSE
            v_capacidade := 1;
        END CASE;

        INSERT INTO Jazigo(id, fila, quadra, numero, capacidade, tipo)
        VALUES (global_id_seq.NEXTVAL, v_fila, v_quadra, v_numero, v_capacidade, v_tipo);
      END LOOP;
    END LOOP;
  END LOOP;
END;
/

---- POPULAR JAZIGOS END ----

---- POPULAR MATERIAIS BEGIN ----

DECLARE
    v_materiais SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Caixão',
    'Urna Funerária',
    'Cimento',
    'Areia',
    'Tijolo',
    'Mármore',
    'Granito',
    'Placa de Identificação',
    'Flores Artificiais',
    'Velas',
    'Lona de Cobertura',
    'Pá',
    'Carrinho de Transporte',
    'Uniforme de Funcionário',
    'Luvas de Borracha');

    v_descricoes SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Caixão de madeira usado para sepultamento tradicional',
    'Recipiente usado para armazenar cinzas em cremações',
    'Usado em obras de jazigos e sepulturas',
    'Componente básico para mistura de concreto',
    'Material de alvenaria para estruturas de túmulos',
    'Revestimento decorativo para túmulos e lápides',
    'Pedra resistente utilizada na construção de jazigos',
    'Placa metálica ou de pedra com dados do falecido',
    'Flores decorativas para ornamentar túmulos',
    'Velas utilizadas em cerimônias e homenagens',
    'Proteção contra chuva durante cerimônias',
    'Ferramenta de escavação para sepulturas',
    'Carrinho usado para transporte de corpos e materiais',
    'Roupas padronizadas para equipe do cemitério',
    'Luvas para proteção durante manuseio de materiais');

    v_nome VARCHAR2(100);
    v_descricao VARCHAR2(500);

BEGIN
    FOR i in 1..v_materiais.COUNT LOOP
        v_nome := v_materiais(i);
        v_descricao := v_descricoes(i);

        INSERT INTO Material(id, nome, descricao)
        VALUES (global_id_seq.NEXTVAL, v_nome, v_descricao);
    END LOOP;
END;
/ 
---- POPULAR MATERIAIS END ----