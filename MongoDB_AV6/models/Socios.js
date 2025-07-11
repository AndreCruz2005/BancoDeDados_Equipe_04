import db from "../config/db.js";

const socioSchema = new db.Schema({
  _id:{type: db.Schema.Types.ObjectId, ref:"Pessoa"},
  socioDesde: {type: Date, required: true},
  pagamentoMensal: {type: Number, required: true},
  tipoSocio: String
});

export default db.model("Socio", socioSchema);
