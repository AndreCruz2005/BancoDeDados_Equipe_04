SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';

-- Esse código pega o ID todos os funcionários e imprime as informações de cada funcionário na tabela Pessoa
BEGIN
  FOR rec IN (SELECT * FROM Funcionario) LOOP
    DECLARE
      v_nome_pessoa   VARCHAR2(100);
      v_sexo_pessoa   VARCHAR2(10);
      v_data_pessoa   DATE;
      v_tipo_pessoa   VARCHAR2(100);
    BEGIN
      SELECT nome, sexo, data_nascimento, tipo
      INTO v_nome_pessoa, v_sexo_pessoa, v_data_pessoa, v_tipo_pessoa
      FROM Pessoa
      WHERE id = rec.id;


      DBMS_OUTPUT.PUT_LINE(
        'Pessoa ID: ' || rec.id ||
        ', Nome: ' || v_nome_pessoa ||
        ', Sexo: ' || v_sexo_pessoa ||
        ', Data Nascimento: ' || TO_CHAR(v_data_pessoa, 'DD-MON-YYYY') ||
        ', Tipo: ' || v_tipo_pessoa
      );
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No matching Pessoa found for Familiar ID ' || rec.id);
    END;
  END LOOP;
END;
/

-- Esse código encontra pessoas chamadas Getúlio Vargas. Muito útil.
DECLARE
    v_found_getulio INT := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_found_getulio
    FROM Pessoa
    WHERE nome = 'Getúlio Vargas';

    IF v_found_getulio = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Não tem Getúlio Vargas... :(');
    ELSIF v_found_getulio = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Tem 1 Getúlio Vargas!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tem vários Getúlios Vargas!!!');
    END IF;
END;
/
