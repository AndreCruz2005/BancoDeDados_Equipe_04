import db from "../config/db.js";

const treinadorSchema = new db.Schema({
  _id: { type: String, ref: "Pessoa", required: true },
  contratos: [{ type: db.Schema.Types.ObjectId, ref: "Contrato" }],
});

export default db.model("Treinador", treinadorSchema);