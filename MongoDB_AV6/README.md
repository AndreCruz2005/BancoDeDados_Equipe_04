## Requerimentos

1. Ter o MongoDB instaldo e rodando localmente e o MongoDB Shell configurado nas suas variáveis de conta.
2. Opcionalmente, gere um povoamento aleatório novo executando o script `gerar_povamento.py`:

```
python MongoDB_AV6/gerar_povamento.py
```

3. Execute o script `povoamento.js` para criar e povoar o banco de dados `gerenciamento_times_esportivos`:

```
mongosh MongoDB_AV6/povoamento.js
```

4. Excute o script `consultas.js` para realizar as consultas no banco de dados:

```
mongosh MongoDB_AV6/consultas.js
```

## Descrição do banco de dados

#### 1. Pessoa

-   N° Documento (ID)
-   Nome
-   Nacionalidade
-   Data Nascimento
-   Emails
-   Telefones
-   Sexo

#### 2. Jogador

-   ID da Pessoa
-   Contratos
-   Lesões
-   Punições
-   Altura
-   Peso

#### 2.1. Lesões

-   ID da Partida em que ocorreu
-   Data de lesão
-   Gravidade da lesão
-   Data de retorno do jogador

#### 2.2. Punições

-   ID da Partida em que ocorreu
-   Tipo de punição
-   Data da punição
-   Quantidade de jogos que o jogador ficará suspenso

#### 3. Treinador

-   ID da Pessoa
-   Contratos

#### 2.3 / 3.1. Contratos

-   Clube (Somente especificado se for outro clube e não o nosso)
-   Tipo (Jogador/Treinador)
-   Data de Início
-   Data de Término
-   Pagamento mensal
-   Status (Ativo/Encerrado)

#### 4. Funcionário

-   ID da Pessoa
-   ID de Gerente
-   Função
-   Salário
-   Data de contratação
-   Data de término de contrato
-   Razão por fim de contrato

#### 5. Sócio

-   ID da Pessoa
-   Data em que começou a ser sócio
-   Pagamento mensal

#### 6. Clubes adversários

-   ID
-   Nome
-   Sigla
-   País

#### 7. Patrocínios

-   CNPJ (ID)
-   Nome
-   Email
-   Data de início
-   Recebimento mensal
-   Data de término

#### 8. Campeonatos

-   ID
-   Nome
-   País
-   Data de início
-   Data de fim
-   Resultado
-   Prêmio monetário
-   Partidas

#### 8.1 Partida

-   ID
-   Clube adversário
-   Treinador
-   Jogadroes titulares
-   Jogadores reserva
-   Data
-   Duração em minutos
-   Gols da nossa equipe
-   Gols do adversário
-   Resultado
-   Quantidade de espectadores
-   Receita gerada

## Checklist AV6

| #   | Comando                       | Usado |
| --- | ----------------------------- | ----- |
| 1   | USE                           | ✅    |
| 2   | FIND                          | ✅    |
| 3   | SIZE                          | ✅    |
| 4   | AGGREGATE                     | ✅    |
| 5   | MATCH                         | ✅    |
| 6   | PROJECT                       | ✅    |
| 7   | GTE                           | ✅    |
| 8   | GROUP                         | ✅    |
| 9   | SUM                           | ✅    |
| 10  | COUNT (COUNTDOCUMENTS)        | ✅    |
| 11  | MAX                           | ✅    |
| 12  | AVG                           | ✅    |
| 13  | EXISTS                        | ✅    |
| 14  | SORT                          | ✅    |
| 15  | LIMIT                         | ✅    |
| 16  | $WHERE                        | ✅    |
| 17  | MAPREDUCE                     | ✅    |
| 18  | FUNCTION                      | ✅    |
| 19  | PRETTY                        | ✅    |
| 20  | ALL                           | ✅    |
| 21  | SET                           |       |
| 22  | TEXT                          |       |
| 23  | SEARCH                        |       |
| 24  | FILTER                        | ✅    |
| 25  | UPDATE (UPDATEONE/UPDATEMANY) |       |
| 26  | SAVE (UPDATEONE/INSERTONE)    |       |
| 27  | RENAMECOLLECTION              |       |
| 28  | COND                          | ✅    |
| 29  | LOOKUP                        | ✅    |
| 30  | FINDONE                       |       |
| 31  | ADDTOSET                      |       |
