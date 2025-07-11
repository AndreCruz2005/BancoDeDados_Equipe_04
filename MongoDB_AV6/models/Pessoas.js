import db from "./../config/db.js";

const pessoaSchema = new db.Schema({
  _id:{type: db.Schema.Types.ObjectId, ref:"Pessoa"},
  nome: { type: String, required: true },
  nacionalidade: { type: String, required: true },
  dataNascimento: Date,
  endereco: String,
  emails: [String],
  telefones: [String],
  sexo: { type: String, enum: ["masculino", "feminino", "outro"] },
});

export default db.model("Pessoa", pessoaSchema);
