import db from "../config/db.js";

const contratoSchema = new db.Schema({
  pessoa: { type: String, ref: "Pessoa", required: true }, // ID da Pessoa (string, mesmo do _id)
  equipe: { type: db.Schema.Types.ObjectId, ref: "Equipe" }, // Se for do nosso clube
  clube: { type: db.Schema.Types.ObjectId, ref: "ClubeAdversario" }, // Se for de outro clube
  tipo: { type: String, enum: ["Treinador", "Jogador"], required: true },
  inicio: { type: Date, required: true },
  fim: Date,
  status: { type: String, default: "Ativo", required: true, },
  pagamentoUnico: Number,
  salarioMensal: Number,
});

export default db.model("Contrato", contratoSchema);
