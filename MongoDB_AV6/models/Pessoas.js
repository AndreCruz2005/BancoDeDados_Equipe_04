import db from "./../config/db.js";

const pessoaSchema = new db.Schema({
    documento: { type: String, required: true, unique: true },
    nome: { type: String, required: true },
    nacionalidade: { type: String, required: true },
    dataNascimento: { type: Date },
    endereco: String,
    emails: [{ type: String }],
    telefones: [{ type: String }],
    sexo: [{ type: String, enum: ["masculino", "feminino", "outro"] }],
});

export default db.model("Pessoa", pessoaSchema);
