import Pessoa from "./../../models/Pessoas.js";

async function inserirPessoa() {
    // Gera número aleatório de documento
    const documento = Array.from({ length: 11 }, () => {
        Math.floor(Math.random() * 10);
    }).join("");

    const novaPessoa = new Pessoa({
        documento: "1024030223404",
        nome: "André Cruz",
        nacionalidade: "Brasileira",
        dataNascimento: new Date("2005-12-16"),
        endereco: "Rua das Flores, 123",
        emails: ["andre@email.com"],
        telefones: ["11999999999"],
        sexo: "masculino",
    });

    try {
        const resultado = await novaPessoa.save();
        console.log("Pessoa inserida com sucesso:", resultado);
    } catch (error) {
        console.error("Erro ao inserir pessoa:", error);
    }
}

inserirPessoa();
