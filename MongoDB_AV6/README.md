### Pré-requisitos

-   Node.js: [https://nodejs.org/](https://nodejs.org/)
-   MongoDB Community Server: [https://www.mongodb.com/try/download/community](https://www.mongodb.com/try/download/community)

### Executar projeto

1. Após clonar o projeto, navegue até esse diretório e instale as dependências:

```bash
cd MongoDB_AV6
npm install
```

2. Inicie o MongoDB

-   Abra o MongoDB Compass para garantir que o servidor está rodando.
-   Verifique que há uma conexão ativa com `mongodb://localhost:27017`.

Alternativamente, para iniciar manualmente:

-   No Windows:
    Vá até a pasta onde o MongoDB foi instalado e execute o `mongod.exe`.

-   No Linux/macOS:
    Execute no terminal:

```bash
mongod
```

3. Depois que o MongoDB estiver rodando, neste diretório execute no terminal algum script, como por exemplo:

```bash
node scripts/povoamento/inserirPessoas.js
```

Se você quiser que o servidor reinicie automaticamente ao salvar o arquivo:

```bash
npx nodemon scripts/povoamento/inserirPessoas.js
```
