import db from "../config/db.js";

const funcionarioSchema = new db.Schema({
  _id:{type: db.Schema.Types.ObjectId, ref:"Pessoa", required: true},
  gerente:{type: db.Schema.Types.ObjectId, ref:"Funcionario"},
  salario:{type: Number, required: true},
  contratadoEm: {type: Date, required: true},
  funcao: String,
  fimContrato: Date,
  razaoFimContrato: String

});

export default db.model("Funcionario", funcionarioSchema);
