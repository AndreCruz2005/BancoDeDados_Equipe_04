CREATE SEQUENCE global_id_seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Packagae com procedures para gerar diversos dados aleatórios para povoamento
CREATE OR REPLACE PACKAGE pkg_random_data IS
    TYPE GridCemiterio IS RECORD (
        quadras INT,
        filas INT,
        numeros INT
    );
    PROCEDURE GERAR_DATA_ALEATORIA(data_referencia IN DATE, tempo_minimo IN NUMBER, tempo_maximo IN NUMBER, v_data OUT DATE);
    PROCEDURE GERAR_GRID_CEMITERIO(qt_jazigos IN INT, grid IN OUT pkg_random_data.GridCemiterio);
END pkg_random_data;
/

CREATE OR REPLACE PACKAGE BODY pkg_random_data IS
    PROCEDURE GERAR_DATA_ALEATORIA(data_referencia IN DATE, tempo_minimo IN NUMBER, tempo_maximo IN NUMBER, v_data OUT DATE) IS 
    BEGIN
        v_data := data_referencia + DBMS_RANDOM.VALUE(tempo_minimo, tempo_maximo);
    END GERAR_DATA_ALEATORIA;

    -- Função recebe um número alvo de jazigos e seleciona uma quantidade aleatória de quadras, filas por quadra e jazigos por fila
    -- que se aproximam do número alvo. Valores da grid devem estar incializados antes da grid ser passada como parâmetro.
    PROCEDURE GERAR_GRID_CEMITERIO(qt_jazigos IN INT, grid IN OUT pkg_random_data.GridCemiterio) IS
    BEGIN
        WHILE grid.quadras * grid.filas * grid.numeros < qt_jazigos LOOP
            grid.quadras := grid.quadras + TRUNC(DBMS_RANDOM.VALUE(1, 3));
            grid.filas := grid.filas + TRUNC(DBMS_RANDOM.VALUE(2, 4));
            grid.numeros := grid.numeros + TRUNC(DBMS_RANDOM.VALUE(3, 5));

        END LOOP;
    END GERAR_GRID_CEMITERIO;
END pkg_random_data;
/

-- Package para configurar o povoamento
CREATE OR REPLACE PACKAGE pkg_global_vars IS
    QT_PESSOAS        INT;
    QT_FUNCIONARIOS   INT;
    QT_FAMILIARES     INT;

    QT_PESSOAS_VIVAS  INT;
    QT_FALECIDOS      INT;

    QT_TELEFONES      INT;
    QT_ENDERECOS      INT;
    QT_JAZIGOS        INT; -- Aproximado, número real irá variar na geração

    QT_EXUMACOES      INT;
    QT_GERENTES       INT;
    QT_SERVICOS       INT;
    QT_MANUTENCOES    INT;
END pkg_global_vars;
/

CREATE OR REPLACE PACKAGE BODY pkg_global_vars IS
BEGIN
    QT_PESSOAS       := 1500;
    QT_FUNCIONARIOS  := 100;
    QT_FAMILIARES    := 300;

    QT_PESSOAS_VIVAS := QT_FUNCIONARIOS + QT_FAMILIARES;
    QT_FALECIDOS     := QT_PESSOAS - QT_PESSOAS_VIVAS;

    QT_TELEFONES     := TRUNC(QT_PESSOAS_VIVAS * 0.9);
    QT_ENDERECOS     := TRUNC(QT_PESSOAS_VIVAS * 0.7);
    QT_JAZIGOS       := TRUNC(QT_FALECIDOS * 0.2);

    QT_EXUMACOES     := 30;
    QT_GERENTES      := 10;
    QT_SERVICOS      := 25;
    QT_MANUTENCOES   := 20;

END pkg_global_vars;
/

---- POVOAR PESSOAS BEGIN ----

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
        'Andrade', 'Rezende', 'Castro', 'Vargas', 'Siqueira', 
        'Barros', 'Azevedo', 'Tavares', 'Peixoto'
    );

    v_sexos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Masculino', 'Feminino');

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
    FOR i IN 1..pkg_global_vars.QT_PESSOAS LOOP
        -- Gera sexo e tipo
        v_sexo := v_sexos(TRUNC(DBMS_RANDOM.VALUE(1, v_sexos.COUNT + 1)));

        IF i < pkg_global_vars.QT_FUNCIONARIOS THEN
            v_tipo := 'Funcionario';
        ELSIF i < pkg_global_vars.QT_PESSOAS_VIVAS THEN
            v_tipo := 'Familiar';
        ELSE
            v_tipo := 'Falecido';
        END IF;

        -- Gera nome completo aleatório
        CASE v_sexo
            WHEN 'Masculino' THEN
                v_nome_completo := v_nomes_masculinos(TRUNC(DBMS_RANDOM.VALUE(1, v_nomes_masculinos.COUNT + 1))) || ' ' ||
                v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, v_sobrenomes.COUNT + 1)));

            WHEN 'Feminino' THEN
                v_nome_completo := v_nomes_femininos(TRUNC(DBMS_RANDOM.VALUE(1, v_nomes_femininos.COUNT + 1))) || ' ' ||
                v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, v_sobrenomes.COUNT + 1)));
        END CASE;

        -- Só pessoas vivas recebem CPF
        CASE v_tipo WHEN 'Falecido' THEN
            v_cpf := NULL;
        ELSE
            v_cpf := gerar_cpf;
        END CASE;   

        -- Define data de nascimento levando em conta o tipo de pessoa
        CASE v_tipo WHEN 'Falecido' THEN
            -- 0 a 225 anos
            pkg_random_data.GERAR_DATA_ALEATORIA(SYSDATE, -1, -225*365.25, v_data_nascimento);
        WHEN 'Funcionario' THEN
            -- 18 a 70 anos
            pkg_random_data.GERAR_DATA_ALEATORIA(SYSDATE, -18*365.25, -70*365.25, v_data_nascimento);
        ELSE -- v_tipo = Familiar
            -- 18 a 110 anos
            pkg_random_data.GERAR_DATA_ALEATORIA(SYSDATE, -18*365.25, -110*365.25, v_data_nascimento);
        END CASE;
       
        INSERT INTO Pessoa(id, nome, cpf, data_nascimento, sexo, tipo)
        VALUES (global_id_seq.NEXTVAL, v_nome_completo, v_cpf, v_data_nascimento, v_sexo, v_tipo);

    END LOOP;
END;
/

-- POVOAR FUNCIONARIOS BEGIN --

DECLARE
    v_funcoes SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Coveiro','Recepcionista', 'Agente Funerário', 'Jardineiro','Eletricista',
    'Encanador', 'Pedreiro', 'Zelador', 'Contador', 'Gerente de Vendas de Jazigos', 
    'Segurança', 'Motorista');

    v_salario NUMBER(8, 2);
    v_funcao VARCHAR2(50);
    v_data_contratacao DATE;

    -- Seleciona todas as pessoas do tipo funcionário que não tem registro correspondente na tabela Funcionário
    -- para criar esse registro correspondente
    CURSOR c_funcionarios IS
        SELECT id, data_nascimento FROM Pessoa
        WHERE tipo = 'Funcionario'
        AND id NOT IN (SELECT id FROM Funcionario);
BEGIN

    FOR f in c_funcionarios LOOP
        v_salario := ROUND(DBMS_RANDOM.VALUE(1600, 20000), 2);    
        v_funcao := v_funcoes(TRUNC(DBMS_RANDOM.VALUE(1, v_funcoes.COUNT + 1)));

        pkg_random_data.GERAR_DATA_ALEATORIA(f.data_nascimento, 18*365.25,  SYSDATE-f.data_nascimento, v_data_contratacao);

        INSERT INTO Funcionario(id, data_contratacao, funcao, salario)
        VALUES (f.id, v_data_contratacao, v_funcao, v_salario);
    END LOOP;
END;
/
-- POVOAR FUNCIONARIOS END --

-- POVOAR FALECIDOS BEGIN --

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

    -- Seleciona pessoas do tipo falecido que não têm um registro correspondente na tabela Falecido.
    CURSOR c_falecidos IS
        SELECT id, data_nascimento FROM Pessoa
        WHERE tipo = 'Falecido'
          AND id NOT IN (SELECT id FROM Falecido);

    -- Função pra gerar número do documento de óbito. Eu não sei se é de fato 32 números, me corrijam.
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

BEGIN
    FOR f IN c_falecidos LOOP
        v_causa_obito := v_causas_morte(TRUNC(DBMS_RANDOM.VALUE(1, v_causas_morte.COUNT + 1)));
        v_numero_documento_obito := gerar_doc_obito;
        pkg_random_data.GERAR_DATA_ALEATORIA(f.data_nascimento, 0, LEAST(SYSDATE-f.data_nascimento, 111*365.25), v_data_falecimento);
     
        INSERT INTO Falecido (id, data_falecimento, causa_obito, numero_documento_obito)
        VALUES (f.id, v_data_falecimento, v_causa_obito, v_numero_documento_obito);
    END LOOP;
END;
/
-- POVOAR FALECIDOS END --

-- POVOAR FAMILIARES BEGIN --

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
-- POVOAR FAMILIARES END --

---- POVOAR PESSOAS END ----

---- POVOAR ENDEREÇOS BEGIN ----

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

    v_estado_idx INT;

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
    FOR i IN 1..pkg_global_vars.QT_ENDERECOS LOOP
        v_estado_idx := TRUNC(DBMS_RANDOM.VALUE(1, 28));

        v_cep := gerar_cep;
        v_estado := v_estados(v_estado_idx);
        v_cidade := v_cidades(v_estado_idx);
        v_bairro := v_bairros(TRUNC(DBMS_RANDOM.VALUE(1, 11)));
        v_rua := v_ruas(TRUNC(DBMS_RANDOM.VALUE(1, 11)));

        INSERT INTO Endereco(cep, estado, cidade, bairro, rua) 
        VALUES (v_cep, v_estado, v_cidade, v_bairro, v_rua);
    END LOOP;
END;
/
---- POVOAR ENDEREÇOS END ----

---- POVOAR TELEFONES BEGIN ----

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
    FOR i IN 1..pkg_global_vars.QT_TELEFONES LOOP
        v_numero := gerar_telefone;
        INSERT INTO Telefone(numero) VALUES (v_numero);
    END LOOP;
END;
/
---- POVOAR TELEFONES END ----

---- POVOAR JAZIGOS BEGIN ----

DECLARE
    v_tipos      SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Simples','Duplo','Familiar','Gaveta');
    v_quadra     INT;
    v_fila       INT;
    v_numero     INT;
    v_capacidade INT;
    v_tipo       VARCHAR2(20);

    v_grid pkg_random_data.GridCemiterio;
BEGIN
    v_grid.quadras := 1;
    v_grid.filas := 1;
    v_grid.numeros := 1;
    pkg_random_data.GERAR_GRID_CEMITERIO(pkg_global_vars.QT_JAZIGOS, v_grid);
    FOR q IN 1..v_grid.quadras LOOP
        FOR f IN 1..v_grid.filas LOOP
            FOR n IN 1..v_grid.numeros LOOP
                v_tipo := v_tipos(TRUNC(DBMS_RANDOM.VALUE(1, v_tipos.COUNT + 1)));
                v_quadra := q;
                v_numero := n;
                v_fila := f;
                CASE v_tipo
                WHEN 'Duplo' THEN
                    v_capacidade := 2;
                WHEN 'Familiar' THEN
                    v_capacidade := TRUNC(DBMS_RANDOM.VALUE(3, 11));
                WHEN 'Gaveta' THEN
                    v_capacidade := TRUNC(DBMS_RANDOM.VALUE(10, 31));
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

---- POVOAR JAZIGOS END ----

---- POVOAR MATERIAIS BEGIN ----

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
---- POVOAR MATERIAIS END ----