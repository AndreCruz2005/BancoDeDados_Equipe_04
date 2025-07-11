import db from "../config/db.js";

const clubeAdversarioSchema = new db.Schema({
    nome: { type: String, required: true },
    sigla: { type: String, required: true },
    pais: String,
    estado: String,
    cidade: String,
  });
  
  export default db.model("ClubeAdversario", clubeAdversarioSchema);
  
