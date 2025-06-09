CREATE TABLE PessoaEndereco(
    cep VARCHAR2(8),
    pessoa_id INT,
    numero VARCHAR2(10),
    complemento VARCHAR2(20),
    PRIMARY KEY(cep, pessoa_id),
    CONSTRAINT fk_pessoaendereco_pessoa FOREIGN KEY(pessoa_id) REFERENCES Pessoa(id),
    CONSTRAINT fk_pessoaendereco_endereco FOREIGN KEY(cep) REFERENCES Endereco(cep)
);

CREATE TABLE PessoaTelefone(
    numero VARCHAR2(13),
    pessoa_id INT,
    PRIMARY KEY(numero, pessoa_id),
    CONSTRAINT fk_pessoatelefone_pessoa FOREIGN KEY(pessoa_id) REFERENCES Pessoa(id),
    CONSTRAINT fk_pessoatelefone_telefone FOREIGN KEY(numero) REFERENCES Telefone(numero)
);


CREATE TABLE Sepultamento(
    falecido_id INT,
    jazigo_id INT,
    data DATE DEFAULT SYSDATE,
    tipo VARCHAR2(50),
    PRIMARY KEY(falecido_id, jazigo_id),
    CONSTRAINT fk_sepultamento_falecido FOREIGN KEY(falecido_id) REFERENCES Falecido(id),
    CONSTRAINT fk_sepultamento_jazigo FOREIGN KEY(jazigo_id) REFERENCES Jazigo(id)
);

CREATE TABLE Exumacao(
    falecido_id INT,
    jazigo_id INT,
    funcionario_id INT,
    data DATE DEFAULT SYSDATE,
    motivo VARCHAR2(500),
    PRIMARY KEY(falecido_id, jazigo_id, funcionario_id),
    CONSTRAINT fk_exumacao_falecido FOREIGN KEY(falecido_id) REFERENCES Falecido(id),
    CONSTRAINT fk_exumacao_jazigo FOREIGN KEY(jazigo_id) REFERENCES Jazigo(id),
    CONSTRAINT fk_exumacao_funcionario FOREIGN KEY(funcionario_id) REFERENCES Funcionario(id)
);

CREATE TABLE Parentesco(
    familiar_id INT,
    falecido_id INT,
    tipo VARCHAR2(50),
    PRIMARY KEY(familiar_id, falecido_id),
    CONSTRAINT fk_parentesco_familiar FOREIGN KEY(familiar_id) REFERENCES Familiar(id),
    CONSTRAINT fk_parentesco_falecido FOREIGN KEY(falecido_id) REFERENCES Falecido(id)
);

CREATE TABLE Gerencia(
    gerente_id INT,
    gerenciado_id INT,
    PRIMARY KEY(gerente_id, gerenciado_id),
    CHECK(gerente_id != gerenciado_id),
    CONSTRAINT fk_gerencia_gerente FOREIGN KEY(gerente_id) REFERENCES Funcionario(id),
    CONSTRAINT fk_gerencia_gerenciado FOREIGN KEY(gerenciado_id) REFERENCES Funcionario(id)
);

CREATE TABLE Solicitacao(
    data_solicitacao DATE DEFAULT SYSDATE PRIMARY KEY,
    servico_id INT,
    familiar_id INT,
    funcionario_id INT,
    status_solicitacao VARCHAR2(18) DEFAULT 'Pagamento Pendente',
    CHECK(status_solicitacao IN ('Pagamento Pendente', 'Em Andamento', 'Concluida', 'Cancelada')),
    CONSTRAINT fk_solicitacao_servico FOREIGN KEY(servico_id) REFERENCES ServicoFunerario(id),
    CONSTRAINT fk_solicitacao_familiar FOREIGN KEY(familiar_id) REFERENCES Familiar(id),
    CONSTRAINT fk_solicitacao_funcionario FOREIGN KEY(funcionario_id) REFERENCES Funcionario(id)

);

CREATE TABLE Utiliza(
    material_id INT,
    manutencao_id INT,
    data_ocorrencia DATE,
    quantidade NUMBER(10,2) DEFAULT 1,
    PRIMARY KEY(material_id, manutencao_id, data_ocorrencia),
    CONSTRAINT fk_utiliza_material FOREIGN KEY(material_id) REFERENCES Material(id),
    CONSTRAINT fk_utiliza_ocorrencia FOREIGN KEY(manutencao_id, data_ocorrencia) REFERENCES OcorrenciaManutecao(manutencao_id, data_ocorrencia)
);