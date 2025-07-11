import Pessoa from "./../../models/Pessoas.js";

async function buscarPessoa() {
    try {
        const pessoas = await Pessoa.find({});
        console.log(pessoas);
    } catch (err) {
        console.error(err);
    }
}

buscarPessoa();
