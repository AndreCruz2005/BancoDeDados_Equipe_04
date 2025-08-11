# Decrição do Minimundo

### Descrição do Mundo Real

Um clube de futebol.

### Entidades

#### 1. Pessoa

-   N° Documento (ID)
-   Nome
-   Nacionalidade
-   Data Nascimento
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
-   Pagamento Mensal

#### 2. Contrato

-   ID
-   ID da Pessoa
-   ID do Clube (Se for de outro clube)
-   Tipo (Treinador, Jogador)
-   Início
-   Fim
-   Salário Mensal
-   Stauts (Ativo, Rescindido, Expirado, etc...)

#### 3. Clubes Adversários

-   ID
-   Nome
-   Sigla
-   País

#### 4. Partidas

-   ID do Adversário
-   ID de Jogadores que jogaram (Multivalorado)
-   ID de Jogadores na reserva (Multivalorado)
-   Data
-   Duração
-   GolsEquipe
-   GolsAdversario
-   Resultado
-   Quantidade Espectadores
-   Receita Gerada

#### 5. Campeonato

-   ID
-   Nome
-   Partidas
-   País
-   Data Início
-   Data Fim
-   Resultado
-   Valor Prêmios

#### 6. Lesões

-   ID da Partida
-   Gravidade
-   DataLesionamento
-   DataRetorno

#### 7. Patrocínios

-   CNPJ (ID)
-   Nome
-   Contato
-   Inicio
-   Fim
-   Pagamento

#### 8. Punições

-   ID
-   ID da Partida
-   Tipo (Cartão amarelo, cartão vermeho, etc...)
-   Data
-   Jogos Suspenso
