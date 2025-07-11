import db from "../config/db.js";

const jogadorSchema = new db.Schema({
  _id: { type: String, ref: "Pessoa", required: true },
  contratos: [{ type: db.Schema.Types.ObjectId, ref: "Contrato" }],
  lesoes: [{ type: db.Schema.Types.ObjectId, ref: "Lesao" }],
  punicoes: [{ type: db.Schema.Types.ObjectId, ref: "Punicao" }],
  altura: Number,
  peso: Number,
});

export default db.model("Jogador", jogadorSchema);