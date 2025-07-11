# Decrição do Minimundo

### Descrição do Mundo Real

Um clube de futebol.

### Entidades

#### 1. Pessoa

-   N° Documento (ID)
-   Nome
-   Nacionalidade
-   Data Nascimento
-   Endereço
-   Emails
-   Telefones
-   Sexo

#### 1.1. Jogador

-   ID da Pessoa
-   Contratos (Referencia IDs de contratos)
-   Lesões (Referencia IDs de lesões)
-   Punições (Referencia IDs de punições)
-   Altura
-   Peso

#### 1.2. Treinador

-   ID da Pessoa
-   Contratos (Referencia IDs de contratos)

#### 1.3. Funcionário

-   ID da Pessoa
-   ID de Gerente
-   Salário
-   ContratadoEm
-   Função
-   Fim do Contrato (Opcional)
-   Razão do Fim do Contrato (Demissão, aposentadoria, morte, etc...)

#### 1.4. Sócio

-   ID da Pessoa
-   SócioDesde
-   Tipo de Sócio
-   Pagamento Mensal

#### 3. Contrato

-   ID
-   ID da Pessoa
-   ID de Equipe (Se for do nosso clube)
-   ID do Clube (Se for de outro time)
-   Tipo (Treinador, Jogador)
-   Início
-   Fim
-   Status
-   Pagamento Único
-   Salário Mensal
-   Stauts (Ativo, Emprestado, Rescindido, Expirado, etc...)

#### 4. Clubes Adversários

-   ID
-   Nome
-   Sigla
-   País
-   Estado
-   Cidade

#### 5. Partidas

-   ID
-   ID do Adversário
-   ID do Campeonato
-   ID da Equipe
-   ID de Jogadores que jogaram (Multivalorado)
-   ID de Jogadores na reserva (Multivalorado)
-   DataHora
-   Local
-   Duração
-   GolsEquipe
-   GolsAdversario
-   Resultado
-   Quantidade Espectadores
-   Receita Gerada

#### 6. Campeonato

-   ID
-   Nome
-   Partidas
-   País
-   Data Início
-   Data Fim
-   Resultado
-   Valor Prêmios
-   Trófeis

#### 7. Equipes

-   ID
-   Nome
-   CriadaEm

#### 8. Lesões

-   ID
-   ID de Jogador
-   Tipo
-   Gravidade
-   DataLesionamento
-   DataRetorno
-   Status

#### 9. Treinamentos

-   ID
-   Jogadores
-   Treinadores
-   DataHora
-   Duração
-   Local

#### 10. Patrocínios

-   ID
-   Nome
-   CNPJ
-   Contato
-   Endereço
-   Equipes
-   Inicio
-   Fim
-   Pagamento Mensal
-   Pagamento Anual
-   Pagamento Único
-   Status

#### 11. Estádios

-   ID
-   Nome
-   Tamanho
-   Endereço
-   Tipo
-   Capacidade
-   AdquiridoEm
-   Custos Mensais

#### 12. Punições

-   ID
-   ID da Partida
-   Tipo (Cartão amarelo, cartão vermeho, etc...)
-   Motivo
-   Data
-   Jogos Suspenso
-   Status
