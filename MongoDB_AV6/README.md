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

## Checklist AV6

| #   | Comando                       | Usado |
| --- | ----------------------------- | ----- |
| 1   | USE                           | ✅    |
| 2   | FIND                          |       |
| 3   | SIZE                          |       |
| 4   | AGGREGATE                     | ✅    |
| 5   | MATCH                         |       |
| 6   | PROJECT                       |       |
| 7   | GTE                           |       |
| 8   | GROUP                         | ✅    |
| 9   | SUM                           | ✅    |
| 10  | COUNT (COUNTDOCUMENTS)        |       |
| 11  | MAX                           |       |
| 12  | AVG                           |       |
| 13  | EXISTS                        |       |
| 14  | SORT                          | ✅    |
| 15  | LIMIT                         |       |
| 16  | $WHERE                        |       |
| 17  | MAPREDUCE                     |       |
| 18  | FUNCTION                      |       |
| 19  | PRETTY                        |       |
| 20  | ALL                           |       |
| 21  | SET                           |       |
| 22  | TEXT                          |       |
| 23  | SEARCH                        |       |
| 24  | FILTER                        |       |
| 25  | UPDATE (UPDATEONE/UPDATEMANY) |       |
| 26  | SAVE (UPDATEONE/INSERTONE)    |       |
| 27  | RENAMECOLLECTION              |       |
| 28  | COND                          |       |
| 29  | LOOKUP                        |       |
| 30  | FINDONE                       |       |
| 31  | ADDTOSET                      |       |
