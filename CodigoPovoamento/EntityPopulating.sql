CREATE SEQUENCE global_id_seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

--POPULAR PESSOAS BEGIN--

DECLARE
    v_nomes SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Ana', 'Carlos', 'Fernanda', 'João', 'Mariana',
    'Lucas', 'Beatriz', 'Pedro', 'Juliana', 'Rafael',
    'Camila', 'Bruno', 'Larissa', 'Diego', 'Patrícia',
    'Rodrigo', 'Letícia', 'Felipe', 'Tatiane', 'Gustavo',
    'Vanessa', 'Marcelo', 'Aline', 'Eduardo', 'Renata',
    'André', 'Sabrina', 'Thiago', 'Paula', 'Vinícius',
    'Natália', 'Fábio', 'Isabela', 'Daniel', 'Simone',
    'Leonardo', 'Carla', 'Mateus', 'Bianca', 'Henrique',
    'Gabriela', 'Murilo', 'Alessandra', 'Vitor', 'Elaine',
    'Igor', 'Luciana', 'Caio', 'Roberta', 'Getúlio'
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

    v_nome VARCHAR2(100);
    v_cpf  VARCHAR2(11);
    v_data_nascimento DATE;
    v_sexo VARCHAR2(9);
    v_tipo VARCHAR2(11);

    FUNCTION gerar_cpf RETURN VARCHAR2 IS
        v_result VARCHAR2(11);
    BEGIN
        v_result := ''; -- Inicializa resultado --
        FOR i IN 1..11 LOOP
            v_result := v_result || TRUNC(DBMS_RANDOM.VALUE(0, 10));
        END LOOP;
        RETURN v_result;
    END;

BEGIN
    FOR i IN 1..100 LOOP
        -- Sorteia um nome e um sobrenome aleatoriamente
        v_nome_completo := v_nomes(TRUNC(DBMS_RANDOM.VALUE(1, 11))) || ' ' ||
                            v_sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, 11)));

        v_tipo := v_tipos(TRUNC(DBMS_RANDOM.VALUE(1, 4)));

        IF TIPO = "Falecido" THEN
            v_cpf := NULL;
        ELSE
            v_cpf := gerar_cpf;
        END IF;
        
        IF v_tipo = 'Falecido' THEN
            v_data_nascimento := TO_DATE('01/01/1800', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*225));
        ELSIF v_tipo = 'Funcionario' THEN
            v_data_nascimento := TO_DATE('01/01/1950', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*57));
        ELSE
            v_data_nascimento := TO_DATE('01/01/1905', 'DD/MM/YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 365*120));
        END IF;


        -- Insere no banco
        INSERT INTO Pessoa(id, )
    END LOOP;
END

--POPULAR PESSOAS END--
